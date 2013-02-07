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
	
//	CTAudioController::Instance()->play("right-behind-you.mp3");
    
	int width = 1600;
	int height = 900;
    
    if(bool tiny = false) {
        width /= 3; height /= 3;
    }
    
	game.Init("Contratempo", width, height, 16, false);
	
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

int mainx()
{
	video::E_DRIVER_TYPE driverType= video::EDT_OPENGL;
	if (driverType==video::EDT_COUNT)
		return 1;

	// create device with full flexibility over creation parameters
	// you can add more parameters if desired, check irr::SIrrlichtCreationParameters
	irr::SIrrlichtCreationParameters params;
	params.DriverType=driverType;
	params.WindowSize=core::dimension2d<u32>(640, 480);
	IrrlichtDevice* device = createDeviceEx(params);

	if (device == 0)
		return 1; // could not create selected driver.

	
	/*
	First, we add standard stuff to the scene: A nice irrlicht engine
	logo, a small help text, a user controlled camera, and we disable
	the mouse cursor.
	*/

	video::IVideoDriver* driver = device->getVideoDriver();
	scene::ISceneManager* smgr = device->getSceneManager();
	gui::IGUIEnvironment* env = device->getGUIEnvironment();

	driver->setTextureCreationFlag(video::ETCF_ALWAYS_32_BIT, true);


	//set other font
	env->getSkin()->setFont(env->getFont("../../media/fontlucida.png"));

	// add some help text
	env->addStaticText(
		L"Press 'W' to change wireframe mode\nPress 'D' to toggle detail map\nPress 'S' to toggle skybox/skydome",
		core::rect<s32>(10,421,250,475), true, true, 0, -1, true);

	// add camera
	scene::ICameraSceneNode* camera =
		smgr->addCameraSceneNodeFPS(0,100.0f,1.2f);

//	addCameraSceneNodeFPS(ISceneNode* parent = 0,
//						  f32 rotateSpeed = 100.0f, f32 moveSpeed = 0.5f, s32 id=-1,
//						  SKeyMap* keyMapArray=0, s32 keyMapSize=0, bool noVerticalMovement=false,
//						  f32 jumpSpeed = 0.f, bool invertMouse=false,
//						  bool makeActive=true) = 0;
	
	camera->setPosition(core::vector3df(2700*2,255*2,2600*2));
	camera->setTarget(core::vector3df(2397*2,343*2,2700*2));
	camera->setFarValue(42000.0f);

	// disable mouse cursor
	device->getCursorControl()->setVisible(false);

	// create skybox and skydome
	driver->setTextureCreationFlag(video::ETCF_CREATE_MIP_MAPS, false);

	scene::ISceneNode* skybox=smgr->addSkyBoxSceneNode(
		driver->getTexture("../../media/irrlicht2_up.jpg"),
		driver->getTexture("../../media/irrlicht2_dn.jpg"),
		driver->getTexture("../../media/irrlicht2_lf.jpg"),
		driver->getTexture("../../media/irrlicht2_rt.jpg"),
		driver->getTexture("../../media/irrlicht2_ft.jpg"),
		driver->getTexture("../../media/irrlicht2_bk.jpg"));
	scene::ISceneNode* skydome=smgr->addSkyDomeSceneNode(driver->getTexture("../../media/skydome.jpg"),16,8,0.95f,2.0f);

	driver->setTextureCreationFlag(video::ETCF_CREATE_MIP_MAPS, true);

	// create event receiver
	CTEventReceiver receiver;
	device->setEventReceiver(&receiver);

	/*
	That's it, draw everything.
	*/

	int lastFPS = -1;

	while(device->run())
	if (device->isWindowActive())
	{
		driver->beginScene(true, true, 0 );

		smgr->drawAll();
		env->drawAll();

		driver->endScene();

		// display frames per second in window title
		int fps = driver->getFPS();
		if (lastFPS != fps)
		{
			core::stringw str = L"Leap/Fmod/Irrlicht/Bullet [";
			str += driver->getName();
			str += "] FPS:";
			str += fps;

			device->setWindowCaption(str.c_str());
			lastFPS = fps;
		}
	}

	device->drop();
	
	return 0;
}
