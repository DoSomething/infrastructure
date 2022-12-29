#upload base64 vars

#while read -r a b; do     echo  ; done < secrets.yaml_bkp > dupa.file

# generate env files
for i in `cat test| awk -F: '{print $1}'` ; do echo "    - name: $i
      valueFrom:
        secretKeyRef:
          name: phoenix-next
          key: $i"; done >> environment-qa.yaml 

