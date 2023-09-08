GET
curl -u appuser:sys http://localhost:8888/csp/myapp/test

POST
curl -u appuser:sys -X POST -H 'Content-type: application/json' -d '{a:1}' http://localhost:8080/csp/myapp/test
