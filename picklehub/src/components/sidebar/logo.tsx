import React from "react";

export const Logo = ({ isMobile }: { isMobile?: boolean }) => (
  <div className="flex items-center">
    <img 
      src="/lovable-uploads/0ff7ce02-62e2-4665-b101-44281d8d042c.png"
      alt="PickleHub Logo"
      className="h-8 w-8 mr-2 rounded-full object-cover"
    />
    <span className="text-xl font-bold font-anybody">PICKLEHUB</span>
  </div>
);