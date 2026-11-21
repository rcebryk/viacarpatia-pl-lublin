# Modyfikacja cudzej receptury bez zmieniania jej kodu: plik .bbappend.
#
# Qt ma rysować bezpośrednio na ekranie przez DRM/KMS (platforma eglfs,
# integracja eglfs_kms), z akceleracją OpenGL ES przez GBM.
# Dotyk obsługuje libinput.
# :class-target - tylko Qt dla maszyny docelowej (RPi), nie qtbase-native na hoście
PACKAGECONFIG:append:class-target = " eglfs gbm gles2 kms libinput fontconfig"
