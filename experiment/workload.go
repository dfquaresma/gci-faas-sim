package main

import (
	"bufio"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

const (
	repoPath         = "/home/ubuntu/gci-faas-sim/"
	runtimePath      = repoPath + "runtime/thumb-func/"
	noGciEntryPoint  = "entrypoint_port=8080 "
	gciEntryPoint    = "entrypoint_port=8082 "
	scale            = "scale=0.1 "
	image_url        = "image_url=http://s3.amazonaws.com/wallpapers2/wallpapers/images/000/000/408/thumb/375.jpg?1487671636 "
	runtimeCoreSet   = "taskset 0x1 nice -20 "
	proxyCoreSet     = "taskset 0x2 nice -20 "
	noGcijavaGCFlags = "-server -Xms128m -Xmx128m -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC "
	gcijavaGCFlags   = "-server -Xms128m -Xmx128m -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1NewSizePercent=90 -XX:G1MaxNewSizePercent=90 "
	proxyFlags       = "--port=8080 --target=127.0.0.1:8082 --gci_target=127.0.0.1:8500 --ygen=104857600 "
	jarPath          = runtimePath + "target/thumbnailator-server-maven-0.0.1-SNAPSHOT.jar "
	funcName         = "thumb"
)

var (
	expId       = flag.String("expid", "test", "Experiment's ID, default value is test")
	useGci      = flag.Bool("usegci", false, "Whether to use GCI, default false")
	target      = flag.String("target", "", "function's ip and port separated as host:port. There's no default value and should not start with http")
	logPath     = flag.String("logpath", "", "the absolute path to save logs. It has no default value")
	nReqs       = flag.Int64("nreqs", 10000, "number of requests, default 10000")
	fileName    = flag.String("filename", "", "results file name. It has no default value")
	resultsPath = flag.String("resultspath", "", "absolute path for save results made. It has no default value")
)

func main() {
	flag.Parse()
	if err := checkFlags(); err != nil {
		log.Fatalf("invalid flags: %v", err)
	}
	var setupCommand string
	if *useGci {
		setupCommand = getGciSetupCommand(*logPath, *expId)
	} else {
		setupCommand = getNoGciSetupCommand(*logPath, *expId)
	}
	upServerCmd := setupFunctionServer(setupCommand, *target)
	tsbefore := time.Now()
	if err := upServerCmd.Start(); err != nil {
		log.Fatal(err)
	}
	status, body, err := sendFirstReq(*target)
	if err != nil {
		log.Fatal(err)
	}
	tsafter := time.Now()
	coldStart := time.Since(tsbefore).Nanoseconds()
	output := make([]string, *nReqs+1)
	output[0] = fmt.Sprintf("id,status,responseTime,body,tsbefore,tsafter")
	output[1] = fmt.Sprintf("%d,%d,%d,%s,%d,%d", 0, status, coldStart, body, tsbefore.UnixNano(), tsafter.UnixNano())
	if err := workload(*target, *nReqs, output); err != nil {
		log.Fatal(err)
	}
	if err := createCsv(output, *resultsPath, *fileName); err != nil {
		log.Fatal(err)
	}
}

func checkFlags() error {
	// TO REVIEW
	s := strings.Split(*target, ":")
	if len(s) != 2 {
		return fmt.Errorf("target must seperate ip and port with ':'. target: %s", *target)
	}
	if _, err := strconv.ParseInt(s[1], 10, 64); err != nil {
		return fmt.Errorf("target port must be a integer. target: %s", *target)
	}
	if len(*logPath) == 0 {
		return fmt.Errorf("logPath cannot be empty")
	}
	if *nReqs <= 0 {
		return fmt.Errorf("nReqs must be bigger than zero. nReqs: %d", *nReqs)
	}
	if len(*fileName) == 0 {
		return fmt.Errorf("fileName cannot be empty")
	}
	if _, err := os.Stat(*resultsPath); os.IsNotExist(err) {
		return fmt.Errorf("resultsPath must exist. resultsPath: %s", *resultsPath)
	}
	return nil
}

func getNoGciSetupCommand(logPath, expid string) string {
	gcLogFlags := "-Xlog:gc:file=" + logPath + "nogci-thumb-gc-" + expid + ".log "
	envvars := noGciEntryPoint + scale + image_url + runtimeCoreSet
	flags := noGcijavaGCFlags + gcLogFlags
	logs := ">" + logPath + "nogci-" + funcName + "-stdout-" + expid + ".log 2>" + logPath + "nogci-" + funcName + "-stderr-" + expid + ".log "
	return envvars + "java " + flags + "-jar " + jarPath + logs + "&"
}

func getGciSetupCommand(logPath, expid string) string {
	gcLogFlags := "-Xlog:gc:file=" + logPath + "gci-thumb-gc-" + expid + ".log "
	envvars := gciEntryPoint + scale + image_url + runtimeCoreSet
	runtimeflags := gcijavaGCFlags + gcLogFlags
	libgc := "-Djvmtilib=" + repoPath + "gci-files/libgc.so "
	gciagent := "-javaagent:" + repoPath + "gci-files/gciagent-0.1-jar-with-dependencies.jar=8500 "
	gciFlags := libgc + gciagent
	logs := ">" + logPath + "gci-" + funcName + "-stdout-" + expid + ".log 2>" + logPath + "gci-" + funcName + "-stderr-" + expid + ".log "
	return envvars + "nohup java " + runtimeflags + gciFlags + "-jar " + jarPath + logs + "& " + getProxySetupCommand(logPath, expid)
}

func getProxySetupCommand(logPath, expid string) string {
	logs := ">" + logPath + "gci-proxy-stdout-" + expid + ".log 2>" + logPath + "gci-proxy-stderr-" + expid + ".log "
	return proxyCoreSet + repoPath + "gci-files/gci-proxy " + proxyFlags + logs + "&"
}

func setupFunctionServer(setupCommand, target string) *exec.Cmd {
	ip := strings.Split(target, ":")[0]
	command := "ssh -i ./id_rsa ubuntu@" + ip + " -o StrictHostKeyChecking=no '" + setupCommand + "'"
	upServerCmd := exec.Command("sh", "-c", command)
	return upServerCmd
}

func sendFirstReq(target string) (int, string, error) {
	failsCount := 0
	maxFailsTolerated := 5000
	for {
		resp, err := http.Get("http://" + target)
		if err == nil && resp.StatusCode == http.StatusOK {
			bodyBytes, err := ioutil.ReadAll(resp.Body)
			if err != nil {
				return 0, "", err
			}
			resp.Body.Close()
			return resp.StatusCode, string(bodyBytes), nil
		}
		time.Sleep(2 * time.Millisecond)
		failsCount += 1
		if failsCount == maxFailsTolerated {
			return 0, "", err
		}
	}
}

func workload(target string, nReqs int64, output []string) error {
	for i := int64(2); i <= nReqs; i++ {
		status, responseTime, body, tsbefore, tsafter, err := sendReq(target)
		if err != nil {
			return err
		}
		output[i] = fmt.Sprintf("%d,%d,%d,%s,%d,%d", i, status, responseTime, body, tsbefore, tsafter)
	}
	return nil
}

func sendReq(target string) (int, int64, string, int64, int64, error) {
	before := time.Now()
	resp, err := http.Get("http://" + target)
	if err != nil {
		return 0, 0, "", 0, 0, err
	}
	defer resp.Body.Close()
	after := time.Now()
	bodyBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return 0, 0, "", 0, 0, err
	}
	status := resp.StatusCode
	responseTime := time.Since(before).Nanoseconds()
	body := string(bodyBytes)
	tsbefore := before.UnixNano()
	tsafter := after.UnixNano()
	return status, responseTime, body, tsbefore, tsafter, nil
}

func createCsv(output []string, resultsPath, fileName string) error {
	// TO REVIEW
	file, err := os.OpenFile(resultsPath+fileName, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	datawriter := bufio.NewWriter(file)
	for _, data := range output {
		_, _ = datawriter.WriteString(data + "\n")
	}
	datawriter.Flush()
	file.Close()
	return nil
}
