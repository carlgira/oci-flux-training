#!/bin/bash

main_function() {
USER='opc'

# Resize root partition
printf "fix\n" | parted ---pretend-input-tty /dev/sda print
VALUE=$(printf "unit s\nprint\n" | parted ---pretend-input-tty /dev/sda |  grep lvm | awk '{print $2}' | rev | cut -c2- | rev)
printf "rm 3\nIgnore\n" | parted ---pretend-input-tty /dev/sda
printf "unit s\nmkpart\n/dev/sda3\n\n$VALUE\n100%%\n" | parted ---pretend-input-tty /dev/sda
pvresize /dev/sda3
pvs
vgs
lvextend -l +100%FREE /dev/mapper/ocivolume-root
xfs_growfs -d /

dnf install wget git git-lfs jq python3.11 python3.11-devel.x86_64 python3.11-tkinter libsndfile rustc cargo unzip zip -y

alternatives --set python3 /usr/bin/python3.11

HF_KEY=`curl -L http://169.254.169.254/opc/v1/instance/ | jq -r '.metadata."HF_KEY"'`

# ComfyUI
su -c "git clone https://github.com/comfyanonymous/ComfyUI.git /home/$USER/ComfyUI" $USER
su -c "git clone https://github.com/carlgira/oci-flux-training /home/$USER/oci-flux-training" $USER
su -c "cd /home/$USER/ComfyUI && python3 -m venv venv && source venv/bin/activate && pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu121 &&  pip install -r requirements.txt" $USER
su -c "cp /home/$USER/oci-flux-training/comfyui/start.sh /home/$USER/ComfyUI/start.sh" $USER
su -c "cd /home/$USER/ComfyUI/custom_nodes && git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git" $USER

# Flux
su -c "git clone https://github.com/ostris/ai-toolkit.git /home/$USER/ai-toolkit" $USER
su -c "cd /home/$USER/ai-toolkit && echo HF_TOKEN=$HF_KEY > .env" $USER
su -c "cd /home/$USER/ai-toolkit && git submodule update --init --recursive && python3 -m venv venv && source venv/bin/activate && pip3 install torch && pip3 install -r requirements.txt" $USER
su -c "cp /home/$USER/oci-flux-training/flux/* /home/$USER/ai-toolkit" $USER

su -c "cd /home/$USER/ComfyUI/models/unet && wget --header="Authorization: Bearer $HF_KEY" https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors" $USER
su -c "cd /home/$USER/ComfyUI/models/clip && wget --header="Authorization: Bearer $HF_KEY" https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors" $USER
su -c "cd /home/$USER/ComfyUI/models/clip && wget --header="Authorization: Bearer $HF_KEY" https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors" $USER
su -c "cd /home/$USER/ComfyUI/models/vae && wget --header="Authorization: Bearer $HF_KEY" https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/ae.safetensors" $USER





cat <<EOT >> /etc/systemd/system/comfyui.service


[Unit]
Description=systemd service start comfyui
[Service]
ExecStart=/bin/bash /home/$USER/ComfyUI/start.sh
User=$USER
[Install]
WantedBy=multi-user.target
EOT

systemctl daemon-reload
systemctl enable comfyui.service
systemctl start comfyui.service

echo "Setup finished"
}

main_function 2>&1 >> /var/log/startup.log
