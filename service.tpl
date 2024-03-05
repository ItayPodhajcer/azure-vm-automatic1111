[Unit]
Description=Automatic1111 Stable Deffusion WebUI

[Service]
Type=simple
WorkingDirectory=/stable-diffusion-webui
ExecStart=/stable-diffusion-webui/webui.sh --listen --api
User=${user}
Group=${user}

[Install]
WantedBy=default.target