#include <irrlicht.h>
#include <BulletDynamics/btBulletDynamicsCommon.h>
#include "CTEventReceiver.h"
#include "CTAudioController.h"
#include "CTGameEngine.h"
#include "CTPlayState.h"

using namespace irr;

#ifdef _MSC_VER
#pragma comment(lib, "Irrlicht.lib")
#endif

int main(int argc, char** argv)
{
	CGameEngine game;

	int width = 1600;
	int height = 900;
    
    if(bool tiny = false) {
        width /= 3; height /= 3;
    }
    
	game.Init("Leap", width, height, 16, false);
	
	game.ChangeState( CPlayState::Instance() );
	
	while (game.Running())
	{
		game.HandleEvents();
		game.Update();
		game.Draw();
	}
	
	game.Cleanup();
	
	return 0;
}