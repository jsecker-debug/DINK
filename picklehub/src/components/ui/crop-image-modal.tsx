import { useState, useRef } from 'react'
import ReactCrop, { Crop, PixelCrop, centerCrop, makeAspectCrop } from 'react-image-crop'
import 'react-image-crop/dist/ReactCrop.css'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'

function centerAspectCrop(
  mediaWidth: number,
  mediaHeight: number,
  aspect: number,
) {
  const smallerDimension = Math.min(mediaWidth, mediaHeight)
  return centerCrop(
    makeAspectCrop(
      {
        unit: 'px',
        width: smallerDimension,
        height: smallerDimension,
      },
      aspect,
      mediaWidth,
      mediaHeight,
    ),
    mediaWidth,
    mediaHeight,
  )
}

interface CropImageModalProps {
  isOpen: boolean
  onClose: () => void
  imageSrc: string
  onCropComplete: (croppedImageBlob: Blob) => void
}

export function CropImageModal({ isOpen, onClose, imageSrc, onCropComplete }: CropImageModalProps) {
  const [crop, setCrop] = useState<Crop>()
  const [completedCrop, setCompletedCrop] = useState<PixelCrop>()
  const imgRef = useRef<HTMLImageElement>(null)
  const [loading, setLoading] = useState(false)

  function onImageLoad(e: React.SyntheticEvent<HTMLImageElement>) {
    const { width, height } = e.currentTarget
    setCrop(centerAspectCrop(width, height, 1))
  }

  const getCroppedImg = async (
    image: HTMLImageElement,
    crop: PixelCrop
  ): Promise<Blob> => {
    const canvas = document.createElement('canvas')
    const ctx = canvas.getContext('2d')

    if (!ctx) {
      throw new Error('No 2d context')
    }

    // Set canvas size to the desired crop size
    canvas.width = crop.width
    canvas.height = crop.height

    // Draw the cropped image onto the canvas
    ctx.drawImage(
      image,
      crop.x,
      crop.y,
      crop.width,
      crop.height,
      0,
      0,
      crop.width,
      crop.height
    )

    // Convert the canvas to a blob
    return new Promise((resolve, reject) => {
      canvas.toBlob((blob) => {
        if (blob) {
          resolve(blob)
        } else {
          reject(new Error('Canvas is empty'))
        }
      }, 'image/jpeg', 1)
    })
  }

  const handleSave = async () => {
    try {
      if (!imgRef.current || !completedCrop) return

      setLoading(true)
      const croppedImageBlob = await getCroppedImg(imgRef.current, completedCrop)
      onCropComplete(croppedImageBlob)
      onClose()
    } catch (error) {
      console.error('Error cropping image:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-[90vw] w-full max-h-[90vh] flex flex-col">
        <DialogHeader>
          <DialogTitle>Crop Profile Picture</DialogTitle>
        </DialogHeader>
        <div className="flex flex-col items-center space-y-4 flex-1 overflow-hidden">
          <div className="relative w-full h-full min-h-0 flex-1 flex items-center justify-center overflow-auto p-4">
            <ReactCrop
              crop={crop}
              onChange={(_, percentCrop) => setCrop(percentCrop)}
              onComplete={(c) => setCompletedCrop(c)}
              aspect={1}
              circularCrop
              className="max-h-full"
            >
              <img
                ref={imgRef}
                alt="Profile"
                src={imageSrc}
                onLoad={onImageLoad}
                className="max-w-full max-h-[calc(90vh-10rem)]"
                style={{ objectFit: 'contain' }}
              />
            </ReactCrop>
          </div>
          <div className="flex justify-end space-x-2 w-full pt-4 border-t">
            <Button variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button onClick={handleSave} disabled={loading}>
              {loading ? 'Saving...' : 'Save'}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
} 