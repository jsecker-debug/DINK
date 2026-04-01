import { useMutation, useQueryClient, useQuery } from "@tanstack/react-query";
import { supabase } from "@/lib/supabase";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { toast } from "sonner";
import { X } from "lucide-react";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";

interface Participant {
  id: string;
  name: string;
  level?: number;
  gender?: string;
  Linked?: boolean;
}

export const ParticipantsList = ({ searchQuery = "" }: { searchQuery?: string }) => {
  const queryClient = useQueryClient();

  const { data: participants, isLoading, error } = useQuery({
    queryKey: ["participants"],
    queryFn: async () => {
      console.log('Fetching participants...');
      const { data, error } = await supabase
        .from("participants")
        .select("*")
        .order("name");
      
      if (error) {
        console.error('Error fetching participants:', error);
        throw error;
      }
      
      console.log('Participants fetched:', data);
      return data as Participant[];
    },
  });

  const updateLevel = useMutation({
    mutationFn: async ({ id, level }: { id: string; level: number }) => {
      console.log('Updating participant level:', { id, level });
      const { error } = await supabase
        .from("participants")
        .update({ level })
        .eq("id", id);
      
      if (error) {
        console.error('Error updating participant level:', error);
        throw error;
      }
      
      console.log('Level updated successfully');
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["participants"] });
      toast.success("Level updated successfully");
    },
    onError: (error) => {
      toast.error("Failed to update level");
      console.error("Error updating level:", error);
    },
  });

  const deleteParticipant = useMutation({
    mutationFn: async (id: string) => {
      console.log('Deleting participant:', id);
      const { error } = await supabase
        .from("participants")
        .delete()
        .eq("id", id);
      
      if (error) {
        console.error('Error deleting participant:', error);
        throw error;
      }
      
      console.log('Participant deleted:', id);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["participants"] });
      toast.success("Participant removed successfully");
    },
    onError: (error) => {
      toast.error("Failed to remove participant");
      console.error("Error removing participant:", error);
    },
  });

  const handleLevelChange = (id: string, newValue: string) => {
    const numericValue = parseFloat(newValue);
    if (!isNaN(numericValue)) {
      updateLevel.mutate({ id, level: numericValue });
    }
  };

  const filteredParticipants = participants?.filter(participant =>
    participant.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (error) {
    return <div className="text-center text-red-500">Error loading participants</div>;
  }

  return (
    <Card className="p-6 bg-card border-border">
      {isLoading ? (
        <p className="text-center text-muted-foreground">Loading participants...</p>
      ) : (
        <div className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredParticipants?.map((participant) => (
              <div
                key={participant.id}
                className="flex flex-col sm:flex-row items-start sm:items-center justify-between p-4 bg-accent/5 rounded-lg border border-border gap-2 hover:bg-accent/10 transition-colors"
              >
                <span className="truncate w-full sm:w-auto flex items-center gap-2 text-card-foreground">
                  {participant.Linked && (
                    <span className="w-2 h-2 rounded-full bg-chart-1" title="Linked Account" />
                  )}
                  <span className="font-medium">
                    {participant.name} {participant.gender ? `(${participant.gender.charAt(0)})` : ''}
                  </span>
                </span>
                <div className="flex flex-col sm:flex-row items-start sm:items-center gap-2 w-full sm:w-auto">
                  <div className="flex items-center gap-2 w-full sm:w-auto">
                    <span className="text-sm text-muted-foreground">Level</span>
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger>
                          <Input
                            type="number"
                            value={participant.level?.toString() || "0"}
                            disabled
                            step="0.1"
                            min="0"
                            max="10"
                            className="w-20 bg-muted cursor-not-allowed text-muted-foreground border-border"
                          />
                        </TooltipTrigger>
                        <TooltipContent className="bg-popover border-border text-popover-foreground">
                          <p>Levels will change after scores are submitted</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </div>
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={() => deleteParticipant.mutate(participant.id)}
                    className="text-muted-foreground hover:text-destructive hover:bg-destructive/10"
                  >
                    <X className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            ))}
          </div>
          {filteredParticipants?.length === 0 && (
            <p className="text-center text-muted-foreground">
              No participants found
            </p>
          )}
        </div>
      )}
    </Card>
  );
};
