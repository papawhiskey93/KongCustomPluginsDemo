# KongCustomPluginsDemo
//docker image for micriservice
docker build -t nodejs .

docker tag nodejs papawhiskey93/nodeapp:1.0

docker push papawhiskey93/nodeapp:1.0

//kong setup
kubectl create namespace kong

kubectl create configmap nodejs-config --from-file=myheader -n kong


kubectl create -f https://bit.ly/k4k8s
export PROXY_IP=$(minikube service -n kong kong-proxy --url | head -1)
echo $PROXY_IP

kubectl apply -f ingress-kong.yaml

kubectl apply -f nodejs-deployment.yaml
kubectl apply -f nodejs-service.yaml

kubectl get deploy,po,svc,hpa,configmap -n kong


echo '
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo
  namespace: kong
  annotations:
    plugins.konghq.com: my-custom-plugin 
    konghq.com/strip-path: "true"
    kubernetes.io/ingress.class: kong
    konghq.com/plugins: my-custom-plugin
spec:
  rules:
  - http:
      paths:
      - path: "/insert"
        pathType: "Prefix"
        backend:
          service:
            name: nodejs
            port: 
             number: 3000		   
' | kubectl apply -f -

curl -i $PROXY_IP/insert

echo "
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: my-custom-plugin
  namespace: kong  
config:
  header_value: "my first plugin"
plugin: myheader
" | kubectl apply -f -



kubectl patch ingress demo -n kong -p '{"metadata":{"annotations":{"konghq.com/plugins": "my-custom-plugin"}}}'

curl -i $PROXY_IP/insert

