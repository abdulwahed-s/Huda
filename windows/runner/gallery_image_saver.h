#ifndef RUNNER_GALLERY_IMAGE_SAVER_H_
#define RUNNER_GALLERY_IMAGE_SAVER_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>

class GalleryImageSaver {
 public:
  explicit GalleryImageSaver(flutter::BinaryMessenger* messenger);

 private:
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_GALLERY_IMAGE_SAVER_H_
