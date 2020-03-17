SET COMMAND=kubectl get nodes -o=name
FOR /F "delims=" %%A IN ('%COMMAND%') DO (
    SET TEMPVAR=%%A
    GOTO :last 
)

:last
kubectl drain %TEMPVAR%
