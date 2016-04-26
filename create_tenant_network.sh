
#$1  env name , N1 N2 N3....
#$2  ip 
#

source /etc/nova/openrc


project_count=`openstack project list | grep -i $1 | wc -l`

ip_pre=$2
ip_start=$3

vlan_start=$3
vlan_end=$4

admin_id=`openstack  project list | grep -i admin | awk '{print $2}'`

neutron providernet-range-create --tenant_id  $admin_id --range $vlan_start-$vlan_end --name L3 providerExternal

neutron quota-update --network 500
neutron quota-update --subnet 500
neutron quota-update --port 500


for i in $(seq 1 $project_count); do

#	tenant_name=$1-Project-$i
#	user_name=project$i
#	password=project$i

#	openstack project create $tenant_name
#	openstack user create --project $tenant_name --password $password --enable $user_name
#        openstack role add --project $tenant_name --user $user_name admin

#        tenant_id=`openstack  project list | grep -i admin | awk '{print $2}'`  

	tenant_name=project$i
	tenant_id=$admin_id

        for ((incr=$vlan_start ; incr<$vlan_start+4; incr++ ));do

    		neutron net-create $tenant_name"_L3ext$incr" --shared --router:external --tenant-id ${tenant_id} --provider:network_type=vlan --provider:physical_network=providerExternal --provider:segmentation_id=${incr}

    		ip_sub=${ip_pre}$((incr-$ip_start+1))

    		neutron subnet-create  --tenant-id ${tenant_id} --name $tenant_name"_L3ext$incr-subnet"  --allocation-pool start=$ip_sub.4,end=$ip_sub.254 $tenant_name"_L3ext$incr" $ip_sub.0/24;

	done   

        vlan_start=$(($vlan_start+4))
done
