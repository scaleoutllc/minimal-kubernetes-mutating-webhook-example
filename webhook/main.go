package main

import (
	"encoding/base64"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"github.com/tidwall/gjson"
)

func main() {
	handler := &Webhook{}
	server := &http.Server{
		Addr:         ":8443",
		Handler:      handler,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  60 * time.Second,
	}
	log.Printf("Listening on http://0.0.0.0%s\n", server.Addr)
	err := server.ListenAndServeTLS("server.crt", "server.key")
	if err != nil {
		log.Fatal(err)
	}
}

type Webhook struct{}

func (s *Webhook) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	manifest, err := io.ReadAll(r.Body)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("%s", gjson.GetBytes(manifest, "@pretty"))
	uid := gjson.GetBytes(manifest, "request.uid")
	patches := `[
		{
			"op": "add",
			"path": "/metadata/labels",
			"value": {
				"mutated": "hello-world"
			}
		 }
	]`
	w.Write([]byte(fmt.Sprintf(`{
		"apiVersion": "admission.k8s.io/v1",
        "kind": "AdmissionReview",
		"response": {
		  "uid": "%s",
		  "allowed": true,
		  "patchType": "JSONPatch",
		  "patch": "%s"
		}
	}`, uid, base64.StdEncoding.EncodeToString([]byte(patches)))))
}
