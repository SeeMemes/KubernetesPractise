# Практическое задание на использование технологий Docker + Kubernetes
** **
### Описание задания
В данном домашнем задании нужно было создать веб-сервер с простой *HTML* страницей с любым содержанием. Суть выполнения домашнего задания заключалась в развертке веб-сервера в *Kubernetes Pod-е*, который формируется на основе одного или нескольких *Контейнеров*.
### Заготовка сервера
При помощи простой команды, *Python* может создавать веб-сервер, выводящий содержимое папки, в которой он был развернут из *CMD*. В дальнейшем мы будем использовать эту команду в контейнере для старта сервера с портом 8000.

Команда:
```
python -m http.server 8000
```
Код самой HTML страницы тривиальнее некуда. Единственное отличие от задание - название HTML-страницы не *hello.html*, а *index.html*, поскольку для большей части веб-приложений такое название HTML файла является названием стартовой страницы.

Код страницы:
```
<html>
	<body>
		<h1> HELLO WORLD </h1>
	</body>
</html>
```
### Разворотка Docker контейнера
Dockerfile разворачивается на основе контейнера *Python* версии *3.11.0b3-alpine3.16*. Соответственно исходя из названия, мы будем работать с ОС *Linux Alpine* и набор команд, требуемый для описания *Username*, *UID* и *GID* будет несколько отличаться от популярных вариантов, с которыми работал раньше.
Сначала мы создаем *user-a* с именем *app* и присваиваем ему *UID* и *GID* равные *1001*, а также создаем директорию */app* и присваиваем ее созданному пользователю. Затем мы копируем в наш контейнер файл *index.html* и также присваиваем этот файл нашему пользователю. Ну и после, в качестве рабочей директории указываем созданную нами */app* и исполняем указанную раньше команду по развертке сервера *Python*. В конце пробрасываем порт *8000* наружу, чтобы пользователь могу получить доступ к содержимому контейнера извне.

Код Dockerfile-а:
```
FROM python:3.11.0b3-alpine3.16

ARG USER=app
ARG UID=1001
ARG GID=1001

RUN adduser ${USER} -u $UID -g $GID -D \
    && mkdir -p /app \
    && chown -R ${USER}:${USER} /app
USER ${USER}

COPY --chown=$USER:$USER /index.html /app

WORKDIR /app

CMD python -m http.server 8000

EXPOSE 8000
```

Посредством команд, указанных ниже, мы собираем наш контейнер (*Docker* скачивает все нужные файлы и образ с *DockerHub-а*, поскольку другой усточник не был указан в параметрах, и уже на основе этого собирает обрах контейнера).
```
PS C:\Users\User\Desktop\PRAKTIKA> docker build -t seememes/web:1.0.0 -t seememes/web:latest .
[+] Building 2.5s (9/9) FINISHED
 => [internal] load build definition from Dockerfile                                                                                                                                                              0.0s 
 => => transferring dockerfile: 32B                                                                                                                                                                               0.0s 
 => [internal] load .dockerignore                                                                                                                                                                                 0.0s 
 => => transferring context: 2B                                                                                                                                                                                   0.0s 
 => [internal] load metadata for docker.io/library/python:3.11.0b3-alpine3.16                                                                                                                                     2.3s 
 => [1/4] FROM docker.io/library/python:3.11.0b3-alpine3.16@sha256:7cf87cc4751f0b65df753a5cd6b355e276eaf797c4f9973fc8d81809b24473fd                                                                               0.0s 
 => [internal] load build context                                                                                                                                                                                 0.0s 
 => => transferring context: 31B                                                                                                                                                                                  0.0s 
 => CACHED [2/4] RUN adduser app -u 1001 -g 1001 -D     && mkdir -p /app     && chown -R app:app /app                                                                                                             0.0s 
 => CACHED [3/4] COPY --chown=app:app /index.html /app                                                                                                                                                            0.0s 
 => CACHED [4/4] WORKDIR /app                                                                                                                                                                                     0.0s 
 => exporting to image                                                                                                                                                                                            0.0s 
 => => exporting layers                                                                                                                                                                                           0.0s 
 => => writing image sha256:9f2e1aa92c143a622d09df559c8556801ef88ce1080be3a4840c629af25d9461                                                                                                                      0.0s 
 => => naming to docker.io/seememes/web:1.0.0                                                                                                                                                                     0.0s 
 => => naming to docker.io/seememes/web:latest                                                                                                                                                                    0.0s 

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
```
После этого, мы можем запустить контейнер для проверки его работоспособности и правильности проброски портов.
```
PS C:\Users\User\Desktop\PRAKTIKA> docker run -ti --rm -p 8000:8000 --name web seememes/web:1.0.0 
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
172.17.0.1 - - [11/Jun/2022 13:56:00] "GET / HTTP/1.1" 200 -
172.17.0.1 - - [11/Jun/2022 13:56:00] code 404, message File not found
172.17.0.1 - - [11/Jun/2022 13:56:00] "GET /favicon.ico HTTP/1.1" 404 -
172.17.0.1 - - [11/Jun/2022 13:56:05] "GET /index.html HTTP/1.1" 200 -
```
Затем мы сделаем *push* контейнера на *DockerHub*, чтобы опубликовать его. После этого я сделал *pull* нашего контейнера и, действительно, все было успешно загружено на сервер.
```
PS C:\Users\User\Desktop\PRAKTIKA> docker push seememes/web:1.0.0
The push refers to repository [docker.io/seememes/web]
5f70bf18a086: Layer already exists
7e808387b286: Layer already exists
70a034bd3d0f: Layer already exists
cd3bb2f043bd: Layer already exists
3fbd57df6b81: Layer already exists
b281fc4ac9f4: Layer already exists
09c126bb3acd: Layer already exists
24302eb7d908: Layer already exists
1.0.0: digest: sha256:ae84fd432e9ed8340c6ed73e8a065441e78157a19a5fe58ea886e2fb2493ed06 size: 1989

PS C:\Users\User\Desktop\PRAKTIKA> docker pull seememes/web:1.0.0
1.0.0: Pulling from seememes/web
Digest: sha256:ae84fd432e9ed8340c6ed73e8a065441e78157a19a5fe58ea886e2fb2493ed06
Status: Image is up to date for seememes/web:1.0.0
docker.io/seememes/web:1.0.0
```
### Разворотка Контейнера в Kubernetes Pod-e
Для развертывания *Container-a* в *Pod-e*, а также развертывания нескольких *Pod-ов* в *Deployment-e* был установлен *Minikube*, так как он просто в установке и использовании.
Сам *Pod* был описан в файле *pod.yaml*. Он содержит в себе описание версии, типа, метаданные об имени приложения и среде запуска, ну и также описание самого контейнера, который в нем мы будем запускать.
Касаемо *Deployment-a*, в нем также описывается имя приложения и среда запуска, но из особенностей: мы можем указать селектор для *Pod-ов*. После чего мы обязательно описываем, какие контейнеры в себе будет содержать *Pod-ы*, хранящиеся в *Deployment-e*.

Код Pod-a:
```
apiVersion: v1
kind: Pod
metadata:
        name: web
        labels:
                env: test
spec: 
        containers:
                - name: webapp
                  image: seememes/web:1.0.0
                  imagePullPolicy: IfNotPresent

```

Код Deployment-a:
```
apiVersion: apps/v1
kind: Deployment
metadata: 
  name: webapp-deployment
  labels:
    app: web
    env: test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: webapp
        image: seememes/web:1.0.0
        imagePullPolicy: IfNotPresent
```

Статус кластера:
```
PS C:\Users\User\Desktop\PRAKTIKA> minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

Применение *manifest-a Pod-a*:
```
PS C:\Users\User\Desktop\PRAKTIKA> kubectl apply -f pod.yaml -n default
pod/web created
```
Теперь создадим новый *Namespace* и развернем в нем наш *Deployment*. Для создания *Namespace-а* был создан файл *praktika_namespace.yaml*, как раз содержащий название *praktika* (и проверим правильность создания соответствующей командой).

Создание *Namespace-a* и применение *manifest-a Development-a*:
```
PS C:\Users\User\Desktop\PRAKTIKA> kubectl create -f ./praktika_namespace.yaml
namespace/praktika created
PS C:\Users\User\Desktop\PRAKTIKA> kubectl get ns
NAME              STATUS   AGE
default           Active   26h
kube-node-lease   Active   26h
kube-public       Active   26h
kube-system       Active   26h
praktika          Active   3s
PS C:\Users\User\Desktop\PRAKTIKA> kubectl apply -f deployment.yaml -n praktika
deployment.apps/webapp-deployment created
```

Теперь проверим все сущности, что мы создали:
```
PS C:\Users\User\Desktop\PRAKTIKA> kubectl apply -f pod.yaml
pod/web created
PS C:\Users\User\Desktop\PRAKTIKA> kubectl get pods
NAME   READY   STATUS    RESTARTS   AGE
web    1/1     Running   0          4s

PS C:\Users\User\Desktop\PRAKTIKA> kubectl apply -f deployment.yaml -n praktika       
deployment.apps/webapp-deployment created
PS C:\Users\User\Desktop\PRAKTIKA> kubectl get pods -n praktika
NAME                                 READY   STATUS    RESTARTS   AGE
webapp-deployment-5c796866dc-lmmrl   1/1     Running   0          9s
webapp-deployment-5c796866dc-rd8gd   1/1     Running   0          9s
```

Для проверки работоспособности Pod-ов перенаправим порт пода *web* на *54321*, а порт пода *webapp-deployment-5c796866dc-rd8gd* на *12345*:
```
PS C:\Users\User\Desktop\PRAKTIKA> kubectl port-forward web 54321:8000                                           
Forwarding from 127.0.0.1:54321 -> 8000
Forwarding from [::1]:54321 -> 8000
Handling connection for 54321
Handling connection for 54321

PS C:\Users\User\Desktop\PRAKTIKA> kubectl port-forward webapp-deployment-5c796866dc-rd8gd 12345:8000 -n praktika
Forwarding from 127.0.0.1:12345 -> 8000
Forwarding from [::1]:12345 -> 8000
```

После успешной отработки, стоит завершить работу *Deployment-a*, *Pod-a* и *minikube-a*:
```
PS C:\Users\User\Desktop\PRAKTIKA> kubectl delete deploy webapp-deployment -n praktika
deployment.apps "webapp-deployment" deleted

PS C:\Users\User\Desktop\PRAKTIKA> kubectl delete pod web
pod "web" deleted

PS C:\Users\User\Desktop\PRAKTIKA> kubectl get pod
No resources found in default namespace.

PS C:\Users\User\Desktop\PRAKTIKA> kubectl get pod -n praktika
No resources found in praktika namespace.

PS C:\Users\User\Desktop\PRAKTIKA> kubectl get deploy -n praktika
No resources found in praktika namespace.

PS C:\Users\User\Desktop\PRAKTIKA> minikube stop
✋  Узел "minikube" останавливается ...
🛑  Выключается "minikube" через SSH ...
🛑  Остановлено узлов: 1.
```

### Описание Pod-a и Deployment-a 
Результат команды *kubectl describe pod web*:
```
PS C:\Users\User\Desktop\PRAKTIKA> kubectl describe pod web
Name:         web
Namespace:    default
Priority:     0
Node:         minikube/192.168.49.2
Start Time:   Sat, 11 Jun 2022 20:55:07 +0300
Labels:       env=test
Annotations:  <none>
Status:       Running
IP:           172.17.0.3
IPs:
  IP:  172.17.0.3
Containers:
  webapp:
    Container ID:   docker://50afb1cf975da4ca0badc48547bdf53ebe89715470389b1cd455ecfb8a17c38f
    Image:          seememes/web:1.0.0
    Image ID:       docker-pullable://seememes/web@sha256:ae84fd432e9ed8340c6ed73e8a065441e78157a19a5fe58ea886e2fb2493ed06
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Sat, 11 Jun 2022 20:55:08 +0300
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-gbhts (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  kube-api-access-gbhts:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  36s   default-scheduler  Successfully assigned default/web to minikube
  Normal  Pulled     35s   kubelet            Container image "seememes/web:1.0.0" already present on machine
  Normal  Created    35s   kubelet            Created container webapp
  Normal  Started    35s   kubelet            Started container webapp
```

Результат команды *kubectl describe pod web*:
```
PS C:\Users\User\Desktop\PRAKTIKA> kubectl describe deploy webapp-deployment -n praktika
Name:                   webapp-deployment
Namespace:              praktika
CreationTimestamp:      Sat, 11 Jun 2022 20:55:22 +0300
Labels:                 app=web
                        env=test
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=web
Replicas:               2 desired | 2 updated | 2 total | 2 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=web
  Containers:
   webapp:
    Image:        seememes/web:1.0.0
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   webapp-deployment-5c796866dc (2/2 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  68s   deployment-controller  Scaled up replica set webapp-deployment-5c796866dc to 2
```
** **
Работу выполнил: Провоторов Александр Владимирович
[Ссылка на DockerHub](https://hub.docker.com/repository/docker/seememes/web)