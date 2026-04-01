import React from "react";
import { X } from "lucide-react";
import { DrawerClose } from "@/components/ui/drawer";
import {
  SidebarContent as BaseSidebarContent,
  SidebarGroup,
  SidebarGroupContent,
} from "@/components/ui/sidebar";
import { Logo } from "./logo";
import { NavigationMenu } from "./navigation-menu";

export const SidebarContent = ({ isMobile }: { isMobile?: boolean }) => {
  return (
    <>
      <div className="flex items-center justify-between h-16 px-2 mb-2 bg-[#f9fafb] shadow-[0_2px_4px_0px_rgba(0,0,0,0.1)] rounded-lg">
        <Logo isMobile={isMobile} />
        {isMobile && (
          <DrawerClose className="p-2 hover:bg-gray-100 rounded-lg lg:hidden">
            <X className="h-5 w-5" />
          </DrawerClose>
        )}
      </div>
      <div className="bg-white rounded-lg">
        <BaseSidebarContent className="px-1 py-1">
          <SidebarGroup>
            <SidebarGroupContent className="space-y-0.5">
              <NavigationMenu />
            </SidebarGroupContent>
          </SidebarGroup>
        </BaseSidebarContent>
      </div>
    </>
  );
};