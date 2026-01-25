# Variables
KUBESPRAY_DIR=kubespray

.PHONY: clone-kubespray
clone-kubespray:
	@if [ -d "$(KUBESPRAY_DIR)" ]; then \
		echo "Directory $(KUBESPRAY_DIR) exists."; \
	else \
		echo "Directory $(KUBESPRAY_DIR) doesn't exist, cloning..."; \
		git clone https://github.com/kubernetes-sigs/kubespray.git $(KUBESPRAY_DIR); \
	fi

.PHONY: kubespray-launch
kubespray-launch: clone-kubespray
	@echo "Starting Kubespray..."
	@cd $(KUBESPRAY_DIR) && ansible-playbook -i ../inventory.ini cluster.yml -v -b
	@echo "Kubespray completed."

.PHONY: kubespray-clean
kubespray-clean:
	@echo "Removing the $(KUBESPRAY_DIR) directory..."
	@rm -rf $(KUBESPRAY_DIR)
	@echo "Cleanup completed."

kubespray: kubespray-launch

