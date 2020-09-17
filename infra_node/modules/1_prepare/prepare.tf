################################################################
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# ©Copyright IBM Corp. 2020
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################

data "ibm_pi_image" "bastion" {
    pi_image_name           = var.rhel_image_name
    pi_cloud_instance_id    = var.service_instance_id
}

## Fix for Terraform CRASH.. always create new public network
resource "ibm_pi_network" "public_network" {
    pi_network_name           = "${var.cluster_id}-pub-net"
    pi_cloud_instance_id      = var.service_instance_id
    pi_network_type           = "pub-vlan"
}

resource "ibm_pi_key" "key" {
    pi_cloud_instance_id = var.service_instance_id
    pi_key_name          = "${var.cluster_id}-keypair"
    pi_ssh_key           = var.public_key
}

resource "ibm_pi_instance" "bastion" {
    count                   = var.bastion["count"] 
    pi_memory               = var.bastion["memory"]
    pi_processors           = var.bastion["processors"]
    pi_instance_name        = "${var.cluster_id}-bastion-${count.index}"
    pi_proc_type            = var.processor_type
    pi_image_id             = data.ibm_pi_image.bastion.id
    pi_network_ids          = [ibm_pi_network.public_network.network_id]
    pi_key_pair_name        = ibm_pi_key.key.key_id
    pi_sys_type             = var.system_type
    pi_cloud_instance_id    = var.service_instance_id
    pi_volume_ids           = null
    # Fix for default route on public interface
    pi_user_data            = base64encode(
                                templatefile(
                                    "${path.module}/templates/fix_default_route.sh",
                                    {pub_gateway = cidrhost(ibm_pi_network.public_network.pi_cidr,1)}
                                )
                              )
}
