
import GameManager from "@/components/game-manager/GameManager";

const Index = () => {
  return (
    <div className="h-full bg-gray-50">
      <div className="max-w-full mx-auto py-20 px-6">
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-primary font-anybody">Scheduler</h1>
          <p className="text-gray-600 mt-2">Generate and manage game schedules</p>
        </div>

        <GameManager />
      </div>
    </div>
  );
};

export default Index;
