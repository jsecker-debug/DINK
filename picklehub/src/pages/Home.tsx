
import { Link } from "react-router-dom";
import { ArrowRight } from "lucide-react";
import { Card } from "@/components/ui/card";
import { GradientButton } from "@/components/ui/gradient-button";
import { Button } from "@/components/ui/button";

const Home = () => {
  return (
    <div className="h-full">
      <div className="max-w-4xl mx-auto py-12 px-6">
        <div className="mb-12">
          <h1 className="text-4xl font-bold text-foreground">Welcome to <span className="font-emblema-one text-primary">DINK</span></h1>
          <p className="text-muted-foreground mt-4 text-lg">
            Your complete solution for managing pickleball sessions and schedules.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-12">
          <Link to="/scheduler">
            <Button className="w-full h-12 text-primary-foreground">
              Scheduler
            </Button>
          </Link>
          <Link to="/participants">
            <Button className="w-full h-12 text-primary-foreground">
              Participants
            </Button>
          </Link>
          <Link to="/sessions">
            <Button className="w-full h-12 text-primary-foreground">
              Sessions
            </Button>
          </Link>
        </div>

        <div className="space-y-8">
          <Card className="p-8 border-border bg-card">
            <h2 className="text-2xl font-bold mb-6 text-card-foreground">How It Works</h2>
            <div className="space-y-6">
              <div className="flex items-start gap-4">
                <div className="bg-primary text-primary-foreground w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 text-sm font-medium">1</div>
                <div>
                  <p className="font-medium text-card-foreground">Create a Session</p>
                  <p className="text-muted-foreground">Start by creating a new session in the {" "}
                    <Link to="/sessions" className="text-primary hover:underline">Sessions</Link> page. 
                    Choose your date and venue.
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-4">
                <div className="bg-primary text-primary-foreground w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 text-sm font-medium">2</div>
                <div>
                  <p className="font-medium text-card-foreground">Generate Schedule</p>
                  <p className="text-muted-foreground">Use the {" "}
                    <Link to="/scheduler" className="text-primary hover:underline">Scheduler</Link> to 
                    generate game rotations and save them to your session.
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-4">
                <div className="bg-primary text-primary-foreground w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 text-sm font-medium">3</div>
                <div>
                  <p className="font-medium text-card-foreground">Manage Players</p>
                  <p className="text-muted-foreground">Add and manage your players in the {" "}
                    <Link to="/participants" className="text-primary hover:underline">Participants</Link> page.
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-4">
                <div className="bg-primary text-primary-foreground w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 text-sm font-medium">4</div>
                <div>
                  <p className="font-medium text-card-foreground">Edit Positions</p>
                  <p className="text-muted-foreground">During the session, you can adjust player positions in the {" "}
                    <Link to="/sessions" className="text-primary hover:underline">Sessions</Link> page.
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-4">
                <div className="bg-primary text-primary-foreground w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 text-sm font-medium">5</div>
                <div>
                  <p className="font-medium text-card-foreground">Record Results</p>
                  <p className="text-muted-foreground">After the session, update the scores and results in the {" "}
                    <Link to="/sessions" className="text-primary hover:underline">Sessions</Link> page.
                  </p>
                </div>
              </div>
            </div>
          </Card>

          <Link to="/sessions">
            <GradientButton className="w-full py-6">
              <span className="flex items-center justify-center gap-2 text-lg font-medium">
                Get Started
                <ArrowRight className="w-5 h-5" />
              </span>
            </GradientButton>
          </Link>
        </div>
      </div>
    </div>
  );
};

export default Home;
