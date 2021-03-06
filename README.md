# KongCustomPluginsDemo

docker build -t nodejs .
docker run -d --name nodejs -p 3000:3000 nodejs
localhost:3000

docker tag nodejs papawhiskey93/nodeapp:1.0

docker push papawhiskey93/nodeapp:1.0



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
    konghq.com/strip-path: "true"
    kubernetes.io/ingress.class: kong
    konghq.com/plugins: my-custom-plugin
spec:
  rules:
  - http:
      paths:
      - path: "/"
        pathType: Prefix
        backend:
          service:
            name: nodejs
            port: 
             number: 3000		   
' | kubectl apply -f -

echo "
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: my-custom-plugin
  namespace: kong  
plugin: myheader
" | kubectl apply -f -


kubectl patch ingress demo -n kong -p '{"metadata":{"annotations":{"konghq.com/plugins": "my-custom-plugin"}}}'

--for autoscaling
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://192.168.49.2:30804; done"

curl -i $PROXY_IP/insert

--valid request
curl -X POST -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJUZW5hbnRJZCI6MSwiT01TSWQiOjEsInVzZXJuYW1lIjoiQXNob2siLCJpYXQiOjE1MTYyMzkwMjJ9.EHqyqASHMq0IbGPUdI9s5jTsy1mKS_LhROI0d9aIawU" -H "Content-Type: application/json" -d '{"TenantId" : 1 , "OMSId" : 1 , "name": "linuxize", "email": "linuxize@example.com"}' $PROXY_IP/home

--no username
curl -X POST -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJUZW5hbnRJZCI6MSwiT01TSWQiOjF9.xL7gyzxXLOR1zHDToMs4CRAq92U107oMC91nF8BqT0Q" -H "Content-Type: application/json" -d '{"TenantId" : 1 , "OMSId" : 1 , "name": "linuxize", "email": "linuxize@example.com"}' $PROXY_IP/home

--invalid key
curl -X POST -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJUZW5hbnRJZCI6MSwiT01TSWQiOjF9.734P6TcrCEEPyibS-POhMuBTd2Q-k5sIXvuBPXLqVyg" -H "Content-Type: application/json" -d '{"TenantId" : 1 , "OMSId" : 1 , "name": "linuxize", "email": "linuxize@example.com"}' $PROXY_IP/home



