#!/bin/bash

echo "=== Rook/Ceph Storage Issues - Media namespace (Ceph in storage namespace) ==="
echo "Timestamp: $(date)"
echo

# Check media namespace pods and their storage
echo "1. All pods in media namespace:"
kubectl get pods -n media -o wide

echo -e "\n2. Failed/Problematic pods in media namespace:"
kubectl get pods -n media | grep -E "(Error|CrashLoopBackOff|Pending|ContainerCreating|PodInitializing|ImagePullBackOff)"

echo -e "\n3. PVCs in media namespace with detailed status:"
kubectl get pvc -n media -o wide

echo -e "\n4. PVs bound to media namespace PVCs:"
kubectl get pv | grep media

echo -e "\n5. Events in media namespace (last 30):"
kubectl get events -n media --sort-by='.lastTimestamp' | tail -30

echo -e "\n6. VolumeAttachments for media namespace:"
kubectl get volumeattachment | grep media

# Check for specific PVC issues
echo -e "\n7. Detailed PVC descriptions (looking for mount issues):"
for pvc in $(kubectl get pvc -n media -o name); do
    echo "--- $pvc ---"
    kubectl describe $pvc -n media
    echo
done

# Ceph tools and status from storage namespace
echo -e "\n8. Ceph Cluster Health:"
kubectl -n storage exec -it deploy/rook-ceph-tools -- ceph health detail

echo -e "\n9. Ceph OSD status:"
kubectl -n storage exec -it deploy/rook-ceph-tools -- ceph osd status

echo -e "\n10. Ceph RBD images:"
kubectl -n storage exec -it deploy/rook-ceph-tools -- rbd ls ceph-blockpool

echo -e "\n11. Ceph pools and usage:"
kubectl -n storage exec -it deploy/rook-ceph-tools -- ceph df

# Check storage namespace Rook/Ceph components
echo -e "\n12. All pods in storage namespace:"
kubectl get pods -n storage -o wide

echo -e "\n13. CSI RBD plugin pods in storage namespace:"
kubectl get pods -n storage -l app=csi-rbdplugin -o wide

echo -e "\n14. Rook operator logs from storage namespace:"
kubectl logs -n storage -l app=rook-ceph-operator --tail=50

echo -e "\n15. CSI RBD plugin errors from storage namespace:"
kubectl logs -n storage -l app=csi-rbdplugin --since=2h | grep -i -E "(error|failed|timeout)"

echo -e "\n16. Storage namespace events:"
kubectl get events -n storage --sort-by='.lastTimestamp' | tail -20

# Check nodes where media pods are scheduled
echo -e "\n17. Node capacity and pressure:"
kubectl describe nodes | grep -A 5 -B 5 -E "(Pressure|OutOfDisk|DiskPressure)"
