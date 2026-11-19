#ifndef HUDA_GALLERY_IMAGE_SAVER_H_
#define HUDA_GALLERY_IMAGE_SAVER_H_
#include <flutter_linux/flutter_linux.h>

// The "Save image" action of the share sheets (`ShareImageSaver` in Dart):
// `saveImage` with {bytes: PNG, name: file name without extension} writes
// `name.png` to the XDG Downloads folder (`name (2).png` and so on beside an
// existing one) and returns true.
FlMethodChannel* gallery_image_saver_new(FlView* view);
#endif
