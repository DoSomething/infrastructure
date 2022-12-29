# Create k8s secret
`kubectl create secret generic -n prod job-timberland-files --from-file=timb_sql.sql=./timb_sql.sql --from-file=timberland_update_script.py=./timberland_update_script.py`
