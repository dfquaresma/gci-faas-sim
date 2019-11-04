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
	runtimeCoreSet   = "taskset 0x1 nice -20 "
	proxyCoreSet     = "taskset 0x2 nice -20 "
	heapSize         = "-Xms445645k -Xmx445645k " // minimum and maximum heap size of ~435mb, from a virtual ambient of 512mb
	proxyYgen        = "--ygen=157286400 "        // proxy forces it's collects after 150mb of heap usage
	awsJvmFlags      = "-XX:MaxHeapSize=445645k -XX:MaxMetaspaceSize=52429k -XX:ReservedCodeCacheSize=26214k -Xshare:on -XX:-TieredCompilation -XX:+UseSerialGC -Djava.net.preferIPv4Stack=true "
	noGcijavaGCFlags = "-server " + heapSize + awsJvmFlags
	gcijavaGCFlags   = "-server " + heapSize + awsJvmFlags + "-XX:NewRatio=1 " // ~210mb to new generation, ~210mb to old generation
	proxyFlags       = "--port=8080 --target=127.0.0.1:8082 --gci_target=127.0.0.1:8500 " + proxyYgen
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
	imageUrl    = flag.String("image_url", "", "Url of the image to be resized. It has no default value")
)

func main() {
	flag.Parse()
	if err := checkFlags(); err != nil {
		log.Fatalf("invalid flags: %v", err)
	}
	var setupCommand string
	if *useGci {
		setupCommand = getGciSetupCommand(*logPath, *imageUrl, *expId)
	} else {
		setupCommand = getNoGciSetupCommand(*logPath, *imageUrl, *expId)
	}
	fmt.Println("SETUP-COMMAND: " + setupCommand)
	upServerCmd := setupFunctionServer(setupCommand, *target)
	tsbefore := time.Now()
	if err := upServerCmd.Start(); err != nil {
		log.Fatal(err)
	}
	fmt.Println("SENDING FIRST REQUEST...")
	status, body, err := sendFirstReq(*target)
	if err != nil {
		log.Fatal(err)
	}
	tsafter := time.Now()
	coldStart := time.Since(tsbefore).Nanoseconds()
	output := make([]string, *nReqs+1)
	output[0] = fmt.Sprintf("id,status,response_time,body,tsbefore,tsafter")
	output[1] = fmt.Sprintf("%d,%d,%d,%s,%d,%d", 0, status, coldStart, body, tsbefore.UnixNano(), tsafter.UnixNano())
	fmt.Println("RUNNING WORKLOAD...")
	if err := workload(*target, *nReqs, output); err != nil {
		log.Fatal(err)
	}
	fmt.Println("SAVING RESULTS...")
	if err := createCsv(output, *resultsPath, *fileName); err != nil {
		log.Fatal(err)
	}
}

func checkFlags() error {
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
	if len(*imageUrl) == 0 {
		return fmt.Errorf("imageurl cannot be empty")
	}
	// TODO: check if imageUrl is a valid Url.
	return nil
}

func getNoGciSetupCommand(logPath, imageUrl, expid string) string {
	gcLogFlags := "-Xloggc:" + logPath + "nogci" + expid + "-thumb-gc.log "
	envvars := noGciEntryPoint + scale + "image_url=" + imageUrl + " " + runtimeCoreSet
	flags := noGcijavaGCFlags + gcLogFlags
	logs := ">" + logPath + "nogci" + expid + "-" + funcName + "-stdout.log 2>" + logPath + "nogci" + expid + "-" + funcName + "-stderr.log "
	return envvars + "java " + flags + "-jar " + jarPath + logs + "&"
}

func getGciSetupCommand(logPath, imageUrl, expid string) string {
	gcLogFlags := "-Xloggc:" + logPath + "gci" + expid + "-thumb-gc.log "
	envvars := gciEntryPoint + scale + "image_url=" + imageUrl + " " + runtimeCoreSet
	runtimeflags := gcijavaGCFlags + gcLogFlags
	libgc := "-Djvmtilib=" + repoPath + "gci-files/libgc.so "
	gciagent := "-javaagent:" + repoPath + "gci-files/gciagent-0.1-jar-with-dependencies.jar=8500 "
	gciFlags := libgc + gciagent
	logs := ">" + logPath + "gci" + expid + "-" + funcName + "-stdout.log 2>" + logPath + "gci" + expid + "-" + funcName + "-stderr.log "
	return envvars + "nohup java " + runtimeflags + gciFlags + "-jar " + jarPath + logs + "& " + getProxySetupCommand(logPath, expid)
}

func getProxySetupCommand(logPath, expid string) string {
	logs := ">" + logPath + "gci" + expid + "-proxy-stdout.log 2>" + logPath + "gci" + expid + "-proxy-stderr.log "
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
	// REMOVE WHEN FIX PROXY's BUG AT FIRST REQ
	if *useGci {
		target = strings.Split(target, ":")[0] + ":8082"
	}
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
		if status != 200 {
			time.Sleep(10 * time.Millisecond)
		}
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
