import { AddParticipantDialog } from "@/components/AddParticipantDialog";
import { ParticipantsList } from "@/components/participants/ParticipantsList";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { useState } from "react";
import { useParticipants } from "@/hooks/useParticipants";

const Participants = () => {
  const [searchInput, setSearchInput] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const { data: participants } = useParticipants();

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setSearchQuery(searchInput);
  };

  const handleClearSearch = () => {
    setSearchInput("");
    setSearchQuery("");
  };

  return (
    <div className="h-full">
      <div className="max-w-full mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-foreground font-anybody">Participants</h1>
          <p className="text-muted-foreground mt-2">Manage your participants</p>
        </div>

        <div className="flex flex-col md:flex-row gap-4 mb-8">
          <div className="w-full md:flex-1">
            <Card className="p-6 bg-card border-border">
              <form onSubmit={handleSearch} className="space-y-4">
                <div className="flex flex-col sm:flex-row gap-4">
                  <Input
                    value={searchInput}
                    onChange={(e) => setSearchInput(e.target.value)}
                    placeholder="Search participants..."
                    className="flex-1"
                  />
                  <div className="flex gap-2">
                    <Button type="submit" className="flex-1 sm:flex-none">
                      Search
                    </Button>
                    <Button 
                      type="button" 
                      variant="outline"
                      onClick={handleClearSearch}
                      className="flex-1 sm:flex-none"
                    >
                      Clear
                    </Button>
                  </div>
                </div>
              </form>
            </Card>
          </div>
          <div className="w-full md:flex-1">
            <Card className="p-6">
              <AddParticipantDialog />
            </Card>
          </div>
        </div>

        <div className="mb-4 text-sm text-gray-500 px-2">
          Total Participants: {participants?.length || 0}
        </div>

        <ParticipantsList searchQuery={searchQuery} />
      </div>
    </div>
  );
};

export default Participants;