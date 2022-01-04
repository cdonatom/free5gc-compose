#! /bin/bash

POD_NAME=f5gc 

echo "Stopping pods and destroying containers"
podman pod stop $POD_NAME
echo "y" | podman pod prune 
echo "y" | podman container prune

echo "Creating a podman pod - name $POD_NAME"
podman pod create --name $POD_NAME
podman pod list


echo "Inspecting volumes..."
podman volume inspect free5gc-compose_dbdata || podman volume create free5gc-compose_dbdata

echo "Creating containers..."
podman create --name=pcf --pod $POD_NAME -e GIN_MODE=release -v /home/cdonato/free5gc-compose/config/pcfcfg.yaml:/free5gc/config/pcfcfg.yaml:Z --network f5gcnet --network-alias pcf --expose 8000 free5gc-compose_free5gc-pcf ./pcf -pcfcfg /free5gc/config/pcfcfg.yaml
podman create --name=upf --pod $POD_NAME --cap-add NET_ADMIN -v /home/cdonato/free5gc-compose/config/upfcfg.yaml:/free5gc/config/upfcfg.yaml:Z -v /home/cdonato/free5gc-compose/config/upf-iptables.sh:/free5gc/free5gc-upfd/upf-iptables-podman.sh:Z --network f5gcnet --network-alias upf free5gc-compose_free5gc-upf bash -c "./upf-iptables-podman.sh && ./free5gc-upfd -f /free5gc/config/upfcfg.yaml"
podman create --name=mongodb --pod $POD_NAME -v free5gc-compose_dbdata:/data/db --network f5gcnet --network-alias db --expose 27017 mongo mongod --port 27017
podman create --name=nrf --pod $POD_NAME -e DB_URI=mongodb://db/free5gc -e GIN_MODE=release -v /home/cdonato/free5gc-compose/config/nrfcfg.yaml:/free5gc/config/nrfcfg.yaml:Z --network f5gcnet --network-alias nrf  --expose 8000 free5gc-compose_free5gc-nrf ./nrf -nrfcfg /free5gc/config/nrfcfg.yaml
podman create --name=webui --pod $POD_NAME -e GIN_MODE=release -v /home/cdonato/free5gc-compose/config/webuicfg.yaml:/free5gc/config/webuicfg.yaml:Z --network f5gcnet -p 5000:5000 free5gc-compose_free5gc-webui ./webui
podman create --name=amf --pod $POD_NAME -e GIN_MODE=release -v /home/cdonato/free5gc-compose/config/amfcfg.yaml:/free5gc/config/amfcfg.yaml:Z --network f5gcnet --network-alias amf --expose 8000 free5gc-compose_free5gc-amf ./amf -amfcfg /free5gc/config/amfcfg.yaml
podman create --name=ausf --pod $POD_NAME -e GIN_MODE=release -v /home/cdonato/free5gc-compose/config/ausfcfg.yaml:/free5gc/config/ausfcfg.yaml:Z --network f5gcnet --network-alias ausf --expose 8000 free5gc-compose_free5gc-ausf ./ausf -ausfcfg /free5gc/config/ausfcfg.yaml
podman create --name=nssf --pod $POD_NAME -e GIN_MODE=release -v /home/cdonato/free5gc-compose/config/nssfcfg.yaml:/free5gc/config/nssfcfg.yaml:Z --network f5gcnet --network-alias nssf --expose 8000 free5gc-compose_free5gc-nssf ./nssf -nssfcfg /free5gc/config/nssfcfg.yaml
podman create --name=udm --pod $POD_NAME -e GIN_MODE=release -v /home/cdonato/free5gc-compose/config/udmcfg.yaml:/free5gc/config/udmcfg.yaml:Z --network f5gcnet --network-alias udm --expose 8000 free5gc-compose_free5gc-udm ./udm -udmcfg /free5gc/config/udmcfg.yaml
podman create --name=udr --pod $POD_NAME -e DB_URI=mongodb://db/free5gc -e GIN_MODE=release -v /home/cdonato/free5gc-compose/config/udrcfg.yaml:/free5gc/config/udrcfg.yaml:Z --network f5gcnet  --network-alias udr --expose 8000 free5gc-compose_free5gc-udr ./udr -udrcfg /free5gc/config/udrcfg.yaml
podman create --name=smf --pod $POD_NAME -e GIN_MODE=release -v /home/cdonato/free5gc-compose/config/smfcfg.yaml:/free5gc/config/smfcfg.yaml:Z -v /home/cdonato/free5gc-compose/config/uerouting.yaml:/free5gc/config/uerouting.yaml:Z --network f5gcnet --network-alias smf --expose 8000 free5gc-compose_free5gc-smf ./smf -smfcfg /free5gc/config/smfcfg.yaml -uerouting /free5gc/config/uerouting.yaml
podman create --name=gnbransim --pod $POD_NAME --cap-add NET_ADMIN  --device /dev/net/tun -v /home/cdonato/free5gc-compose/config/gnbcfg.yaml:/ueransim/config/gnbcfg.yaml:Z --network f5gcnet --network-alias gnb free5gc-compose_ueransim ./nr-gnb -c ./config/gnbcfg.yaml
#podman create --name=ueransim --pod $POD_NAME --cap-add NET_ADMIN --device /dev/net/tun -v /home/cdonato/free5gc-compose/config/uecfg.yaml:/ueransim/config/uecfg.yaml:Z --network f5gcnet --network-alias ue free5gc-compose_ueransim ./nr-ue -c ./config/uecfg.yaml
podman create --name=n3iwf --pod $POD_NAME --cap-add NET_ADMIN -e GIN_MODE=release -v /home/cdonato/free5gc-compose/config/n3iwfcfg.yaml:/free5gc/config/n3iwfcfg.yaml:Z -v /home/cdonato/free5gc-compose/config/n3iwf-ipsec.sh:/free5gc/n3iwf/n3iwf-ipsec.sh:Z --network f5gcnet --network-alias n3iwf free5gc-compose_free5gc-n3iwf bash -c "./n3iwf-ipsec.sh && ./n3iwf -n3iwfcfg /free5gc/config/n3iwfcfg.yaml"

echo "Starting containers..."
podman start mongodb
podman start nrf
podman start webui
podman start amf
podman start ausf
podman start nssf
podman start pcf
podman start udm
podman start udr
podman start smf
podman start upf
podman start n3iwf
podman start -a gnbransim
