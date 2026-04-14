#!/bin/bash
export THEOS=/opt/theos
export THEOS_MAKE_PATH=$THEOS/makefiles
export PATH="$THEOS/bin:$PATH"

# Copy to native Linux filesystem to fix permission issues
rm -rf /tmp/CC26_build
cp -r /mnt/c/Users/Max/CC26 /tmp/CC26_build
cd /tmp/CC26_build
chmod 0755 /tmp/CC26_build

# Fix Windows line endings
find /tmp/CC26_build -type f \( -name "*.m" -o -name "*.h" -o -name "*.xm" -o -name "*.x" -o -name "Makefile" -o -name "control" -o -name "*.plist" \) -exec sed -i 's/\r$//' {} +

make clean
make package 2>&1

# Copy .deb back to Windows
cp -f /tmp/CC26_build/packages/*.deb /mnt/c/Users/Max/CC26/packages/ 2>/dev/null || true
