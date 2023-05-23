# DOCUMENTACION tekton-ci
All manifest of tekton flow

## Tasks
Todas las tasks son sacadas de tekton hub, despues deberiamos hacerlas nosotros.
### git-clone
Como su nombre indica es una task solo para hacer clone de algun repo y el resultado lo mete en un volumen al que tekton llama wokspace para que otras tasks puedan acceder
### docker-push
Esta tarea se encarga del buildeo de un codigo crudo a una imagen docker y pushea la imagen a un registry. Utiliza kaniko para todo el proceso
### git-cli
Este talvez lo podamos fucionar con el clone porque es una copia practicamente, pero te permite insertar comandos de git para hacer mas que clonar, en este caso se ocupa para pushear al repo remoto el cambio del manifiesto
## Pipeplines
### clone-build-pipe
Utiliza las tasks git-clone y docker-push, lo que hace el pipeline es clonar un repo y ese usarlo para buildear una imagen y pushearlo al registry
### manifest-clone-push
Utiliza las tasks git-clone y git-cli para clonar el repo de manifiestos del repo imagen y cambiar en el manifiesto, en este caso un deployment, la version de la imagen utilizada y pushea los cambios.
## Trigger Template
El trigger template establece que se hace cuando se lo invoca, en este caso setea dos pipeline run, uno invoca al clone-build-pipe y el otro al manifest-clone-push. En los pipeline runs tambien se definen las configuraciones del pod y setea los workflows (volumenes) a utilizar.
## Trigger Binding
El trigger binding basicamente es el que setea los parametros recibidos por el template, este tiene acceso como contexto al payload del eventlistener a traves del _body_ y de _extensions_ si es un parametro tratado por un interceptor
## EventListener
En este se setea un servicio al cual se le puede pegar para mandarle informacion (en este caso es un webhook cuando se hace un push a un repo). En este listener se configuran los bindings y templates que van a actuar cuando reciba alguna peticion.
### Interceptors
Tambien se configuran lo que se denomina _interceptors_ que son un mecanismo para control de data, en el cual se le puede especificar que reciba un tipo especifico de informacion y tambien tratar los datos recibidos. En este caso se setean dos interceptors uno de github para recibir la info que envia el webhook solo detectando los push y tambien se setea un CEL (Common Expression Language) el cual se usa para manipular datos, en este caso para obtener la branch name, el mensaje del commit y la url ssh (lo que el cel setea va a _extensions_ en el payload que recibe el trigger binding).
<br/>
Aca esta como configurar un interceptor con varios portales de repos:
https://tekton.dev/docs/triggers/interceptors/
### Service account
El eventlistener necesita un service account, en el siguiente enlace se especifica como hacerlo:
https://tekton.dev/docs/getting-started/triggers/#create-an-eventlistener

## Seguridad
En varios momentos se necesita establecer credenciales para acceder a distintos portales, la solucion consta en crear un secret con las credenciales, en este caso se utiliza un codigo sh con kubectl para no mostrar explicitamente el valor de los secrets ya que lo subo a gh, ademas el secret requiere un type y una annotation especifico para el tipo de credencial. Una vez creado el secret, se crea un service account refenciando a ese secret, y este se establece en donde se vaya a correr (en un taskrun o en un pipelinerun).
<br/>
Todo esto esta especificado en: 
https://tekton.dev/docs/pipelines/auth/

### ssh
No ocupar passphrase para el ssh ya que no se puede utilizar a la hora de automatizar.
Como crear y vincular una clave ssh a github:
https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
<br/>
Para generar una clave publica y privada el comando es,
_si ed25519 no es soportado se puede usar rsa_.
```ssh
ssh-keygen -t ed25519 -C "your_email@example.com"
``` 
La privada es la que se le pasa a tekton a traves del service account para que pueda lograr la conexion ssh.
Es importante establecer primero la conexion con la maquina de la clave privada asi se agrega al archivo _known_hosts_ para tambien pasarlo a tekton.