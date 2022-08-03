#!/bin/bash

# ==============================
# ArchLinux - Installation
#
#
# ==============================

source archlinux-configuration.config

# Clavier
# ==============================
loadkeys "$KEYMAP"

# Réseau
# ==============================

timedatectl set-ntp true

# Partition
# ==============================

# TODO: création des partitions

mkfs.fat -F32 "$BOOT_PARTITION"
mkfs.ext4 "$ROOT_PARTITION"
mkswap "$SWAP_PARTITION"

mount "$ROOT_PARTITION" /mnt
mkdir -p /mnt/boot/efi
mount "$BOOT_PARTITION" /mnt/boot
swapon "$SWAP_PARTITION"

# Système de base
# ==============================

pacstrap /mnt "$BASE_PACKAGES"
pacstrap /mnt "$EXTRA_PACKAGES"
genfstab -U /mnt >> /mnt/etc/fstab

# Configuration de base
# ==============================

arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$TIME_ZONE" /etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt sed 's/#"$LANG"/"$LANG"' /etc/locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt echo "LANG=$LANG" >> /etc/locale.conf
arch-chroot /mnt echo "KEYMAP=$KEYMAP" >> /etc/vconsole.conf
arch-chroot /mnt echo "$HOSTNAME" >> /etc/hostname
arch-chroot /mnt echo "127.0.0.1        localhost" >> /etc/hosts
arch-chroot /mnt echo "::1              localhost" >> /etc/hosts
arch-chroot /mnt echo "127.0.1.1        $HOSTNAME.localdomain   $HOSTNAME" >> /etc/hosts
arch-chroot /mnt mkinitcpio -P

# Chargeur de démarrage
# ==============================

arch-chroot /mnt os-prober
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Utilisateur & Groupe
# ==============================

# TODO: Définir le mot de passe

useradd -m -G "$DEFAULT_GROUPS" "$DEFAULT_USER"


# Personnalisation
# ==============================

# Pacman
arch-chroot /mnt sed 's/#Color/Color/g' /etc/pacman.conf
arch-chroot /mnt sed 's/#VerbosePkgLists/VerbosePkgLists/g' /etc/pacman.conf
arch-chroot /mnt sed 's/#ParallelDownloads = 5/ParallelDownloads = 3/g' /etc/pacman.conf

# Nano
arch-chroot /mnt sed 's/# set indicator/set indicator/g' /etc/nanorc
arch-chroot /mnt sed 's/# set linenumbers/set linenumbers/g' /etc/nanorc
arch-chroot /mnt sed 's/# set mouse/set mouse/g' /etc/nanorc
arch-chroot /mnt sed 's/# set showcursor/set showcursor/g' /etc/nanorc

arch-chroot /mnt sed 's/# include "/usr/share/*.nanorc"/include "/usr/share/*.nanorc"/g' /etc/nanorc

# Sudo
arch-chroot /mnt sed 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers

