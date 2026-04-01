import { Menu } from "lucide-react";
import { useIsMobile } from "@/hooks/use-mobile";
import {
  Drawer,
  DrawerContent,
  DrawerTrigger,
} from "@/components/ui/drawer";
import { Sidebar } from "@/components/ui/sidebar";
import { SidebarContent } from "./sidebar/sidebar-content";

export function AppSidebar() {
  const isMobile = useIsMobile();

  if (isMobile) {
    return (
      <Drawer direction="top">
        <DrawerTrigger asChild>
          <button className="fixed top-4 left-4 p-2 bg-white rounded-lg shadow-sm">
            <Menu className="h-6 w-6" />
          </button>
        </DrawerTrigger>
        <DrawerContent className="p-4">
          <div className="relative bg-white rounded-lg">
            <SidebarContent isMobile={true} />
          </div>
        </DrawerContent>
      </Drawer>
    );
  }

  return (
    <Sidebar className="w-64 p-2 bg-[#f9fafb] border-none">
      <SidebarContent isMobile={false} />
    </Sidebar>
  );
}