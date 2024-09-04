#!/bin/bash

source venv/bin/activate
train_name=$(python3 -c "import random, string; print(''.join(random.choices(string.ascii_letters + string.digits, k=16)))")
file_path="$train_name.yml"
cp train_lora_flux_24gb.yaml $file_path
sed -i "s/train_lora_flux/$train_name/g" "$file_path"

echo "The training id is $train_name"
python run.py $file_path 2>&1 >> output.log &