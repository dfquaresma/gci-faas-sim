# Useful commands

* Compilar e rodar: docker build -t image-name . && docker run --rm --name container-name image-name
* Descobrir IP: docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container-name
* Matar o container: docker kill container-name
* Entrar no container rodando: docker exec -it  container-name ash
* Compilar e rodar no localhost: docker build -t image-name . && docker run --network="host" --rm --name container-name image-name 
* Compilar o gci-proxy para Alpine: cd ${GCI_PROXY_REPO_DIR}; CGO_ENABLED=0 go build --ldflags "-s -w" -a -installsuffix cgo .

