
import { Button } from "@/components/ui/button";
import { Download } from "lucide-react";
import html2canvas from "html2canvas";
import jsPDF from "jspdf";
import { toast } from "sonner";

interface DownloadPdfButtonProps {
  contentId: string;
  fileName: string;
  className?: string;
  children?: React.ReactNode;
}

const DownloadPdfButton = ({ contentId, fileName, className, children }: DownloadPdfButtonProps) => {
  const handleDownload = async () => {
    const element = document.getElementById(contentId);
    if (!element) {
      toast.error("Content not found");
      return;
    }

    try {
      toast.info("Generating PDF...");
      const canvas = await html2canvas(element, {
        backgroundColor: "#ffffff",
        scale: 2,
      });
      
      // Calculate dimensions
      const imgWidth = 210; // A4 width in mm
      const pageHeight = 297; // A4 height in mm
      const imgHeight = (canvas.height * imgWidth) / canvas.width;
      
      const pdf = new jsPDF("p", "mm", "a4");
      
      // Calculate the number of pages needed
      const pagesNeeded = Math.ceil(imgHeight / pageHeight);
      
      // For each page
      for (let page = 0; page < pagesNeeded; page++) {
        // Only add new page if it's not the first page
        if (page > 0) {
          pdf.addPage();
        }
        
        // Calculate what portion of the image to use for this page
        const sourceY = page * canvas.height / pagesNeeded;
        const sourceHeight = canvas.height / pagesNeeded;
        
        // Create a new canvas for this portion
        const pageCanvas = document.createElement('canvas');
        pageCanvas.width = canvas.width;
        pageCanvas.height = sourceHeight;
        
        const context = pageCanvas.getContext('2d');
        if (context) {
          context.fillStyle = '#ffffff';
          context.fillRect(0, 0, pageCanvas.width, pageCanvas.height);
          context.drawImage(
            canvas,
            0,
            sourceY,
            canvas.width,
            sourceHeight,
            0,
            0,
            pageCanvas.width,
            pageCanvas.height
          );
        }
        
        // Add this portion to the PDF
        const imgData = pageCanvas.toDataURL('image/png');
        if (page === 0) {
          pdf.addImage(imgData, 'PNG', 0, 0, imgWidth, pageHeight);
        } else {
          pdf.addImage(imgData, 'PNG', 0, 0, imgWidth, pageHeight);
        }
      }
      
      pdf.save(`${fileName}.pdf`);
      toast.success("PDF downloaded successfully!");
    } catch (error) {
      console.error("Error generating PDF:", error);
      toast.error("Failed to generate PDF");
    }
  };

  return (
    <Button 
      onClick={handleDownload}
      className={className}
    >
      {children || (
        <>
          <Download className="h-4 w-4" />
          Download PDF
        </>
      )}
    </Button>
  );
};

export default DownloadPdfButton;

