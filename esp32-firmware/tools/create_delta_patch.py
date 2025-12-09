#!/usr/bin/env python3
"""
OrthoTrack Delta OTA Patch Creator
Baseado na metodologia DeltaOtaPatchCreatorELT
https://github.com/alexabreup/DeltaOtaPacthCreatorELT

Este script cria patches delta para atualizações OTA eficientes do ESP32.
"""

import sys
import os
import subprocess
import re
import argparse
import hashlib
from pathlib import Path

# Constantes do formato Delta OTA
ESP_DELTA_OTA_MAGIC = 0xfccdde10
MAGIC_SIZE = 4
DIGEST_SIZE = 32
RESERVED_HEADER = 64 - (MAGIC_SIZE + DIGEST_SIZE)

def check_requirements():
    """Verifica e instala dependências necessárias"""
    print("🔍 Verificando dependências...")
    
    # Verificar esptool
    try:
        result = subprocess.run(["esptool.py", "version"], 
                              capture_output=True, text=True, check=True)
        print(f"✅ esptool: {result.stdout.split()[0]}")
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("⚠️  esptool não encontrado, instalando...")
        subprocess.run([sys.executable, "-m", "pip", "install", "esptool"], check=True)
    
    # Verificar detools
    try:
        result = subprocess.run(["detools", "--version"], 
                              capture_output=True, text=True, check=True)
        print(f"✅ detools: {result.stdout.strip()}")
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("⚠️  detools não encontrado, instalando...")
        subprocess.run([sys.executable, "-m", "pip", "install", "detools"], check=True)

def calculate_md5(filepath):
    """Calcula MD5 hash de um arquivo"""
    md5_hash = hashlib.md5()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            md5_hash.update(chunk)
    return md5_hash.hexdigest()

def get_firmware_hash(chip, binary_path):
    """Extrai o hash de validação do firmware usando esptool"""
    print(f"📝 Extraindo hash do firmware base...")
    
    cmd = ["esptool.py", "--chip", chip, "image_info", binary_path]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    
    # Procurar pelo Validation Hash
    match = re.search(r"Validation Hash: ([A-Fa-f0-9]+) \(valid\)", result.stdout)
    
    if match:
        validation_hash = match.group(1)
        print(f"✅ Hash de validação: {validation_hash}")
        return validation_hash
    else:
        raise ValueError("Não foi possível extrair o hash de validação do firmware")

def create_delta_patch(chip, base_binary, new_binary, output_patch):
    """Cria um patch delta entre dois firmwares"""
    print("\n" + "="*60)
    print("🔄 Criando Delta OTA Patch")
    print("="*60)
    
    # Verificar se os arquivos existem
    if not os.path.exists(base_binary):
        raise FileNotFoundError(f"Firmware base não encontrado: {base_binary}")
    if not os.path.exists(new_binary):
        raise FileNotFoundError(f"Firmware novo não encontrado: {new_binary}")
    
    # Obter hash do firmware base
    validation_hash = get_firmware_hash(chip, base_binary)
    
    # Criar patch temporário sem header
    temp_patch = output_patch + ".temp"
    print(f"\n📦 Gerando patch delta...")
    
    cmd = ["detools", "create_patch", "-c", "heatshrink", 
           base_binary, new_binary, temp_patch]
    subprocess.run(cmd, check=True)
    
    # Obter tamanhos
    base_size = os.path.getsize(base_binary)
    new_size = os.path.getsize(new_binary)
    patch_size = os.path.getsize(temp_patch)
    
    print(f"\n📊 Estatísticas:")
    print(f"   Firmware base:  {base_size:,} bytes")
    print(f"   Firmware novo:  {new_size:,} bytes")
    print(f"   Patch delta:    {patch_size:,} bytes")
    print(f"   Economia:       {100 - (patch_size * 100 / new_size):.1f}%")
    
    # Criar patch final com header
    print(f"\n📝 Adicionando header Delta OTA...")
    
    with open(output_patch, "wb") as final_patch:
        # Escrever magic number
        final_patch.write(ESP_DELTA_OTA_MAGIC.to_bytes(MAGIC_SIZE, 'little'))
        
        # Escrever validation hash
        final_patch.write(bytes.fromhex(validation_hash))
        
        # Escrever bytes reservados
        final_patch.write(bytearray(RESERVED_HEADER))
        
        # Escrever conteúdo do patch
        with open(temp_patch, "rb") as temp:
            final_patch.write(temp.read())
    
    # Remover arquivo temporário
    os.remove(temp_patch)
    
    # Calcular MD5 do patch final
    patch_md5 = calculate_md5(output_patch)
    
    print(f"\n✅ Patch criado com sucesso!")
    print(f"📁 Arquivo: {output_patch}")
    print(f"📏 Tamanho: {os.path.getsize(output_patch):,} bytes")
    print(f"🔐 MD5: {patch_md5}")
    
    return {
        'patch_file': output_patch,
        'patch_size': os.path.getsize(output_patch),
        'patch_md5': patch_md5,
        'base_size': base_size,
        'new_size': new_size,
        'compression_ratio': 100 - (patch_size * 100 / new_size)
    }

def create_full_firmware_package(firmware_path, output_path=None):
    """Cria um pacote de firmware completo com metadados"""
    if output_path is None:
        output_path = firmware_path.replace('.bin', '_packaged.bin')
    
    # Simplesmente copiar o firmware (em produção, adicionar metadados)
    import shutil
    shutil.copy(firmware_path, output_path)
    
    firmware_md5 = calculate_md5(output_path)
    firmware_size = os.path.getsize(output_path)
    
    print(f"\n✅ Firmware empacotado!")
    print(f"📁 Arquivo: {output_path}")
    print(f"📏 Tamanho: {firmware_size:,} bytes")
    print(f"🔐 MD5: {firmware_md5}")
    
    return {
        'firmware_file': output_path,
        'firmware_size': firmware_size,
        'firmware_md5': firmware_md5
    }

def main():
    parser = argparse.ArgumentParser(
        description='OrthoTrack Delta OTA Patch Creator',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos:
  # Criar patch delta
  python create_delta_patch.py --chip esp32 \\
    --base firmware_v1.0.0.bin \\
    --new firmware_v1.1.0.bin \\
    --output patch_v1.0.0_to_v1.1.0.bin
  
  # Empacotar firmware completo
  python create_delta_patch.py --chip esp32 \\
    --full firmware_v1.1.0.bin \\
    --output firmware_v1.1.0_packaged.bin
        """
    )
    
    parser.add_argument('--chip', default='esp32',
                       choices=['esp32', 'esp32s2', 'esp32s3', 'esp32c3', 'esp32c6', 'esp32h2'],
                       help='Chip ESP32 (padrão: esp32)')
    
    parser.add_argument('--base', help='Firmware base (.bin)')
    parser.add_argument('--new', help='Firmware novo (.bin)')
    parser.add_argument('--full', help='Firmware completo para empacotar (.bin)')
    parser.add_argument('--output', required=True, help='Arquivo de saída')
    
    args = parser.parse_args()
    
    try:
        # Verificar dependências
        check_requirements()
        
        if args.full:
            # Modo: empacotar firmware completo
            print(f"\n📦 Modo: Firmware Completo")
            result = create_full_firmware_package(args.full, args.output)
            
        elif args.base and args.new:
            # Modo: criar patch delta
            print(f"\n🔄 Modo: Delta Patch")
            result = create_delta_patch(args.chip, args.base, args.new, args.output)
            
        else:
            parser.error("Especifique --base e --new para patch delta, ou --full para firmware completo")
        
        print("\n" + "="*60)
        print("✅ Processo concluído com sucesso!")
        print("="*60)
        
    except Exception as e:
        print(f"\n❌ Erro: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
