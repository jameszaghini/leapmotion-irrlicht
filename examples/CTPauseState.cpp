//
//  CTPauseState.cpp
//  Contratempo
//
//  Created by James Zaghini on 2/01/13.
//
//

#include "CTPauseState.h"

CPauseState CPauseState::m_PauseState;

void CPauseState::Init(CGameEngine* game)
{
	driver = game->device->getVideoDriver();
	smgr = game->device->getSceneManager();
    
    pauseImage = driver->getTexture("paused.png");
//    font = game->device->getGUIEnvironment()->getBuiltInFont();
}

void CPauseState::Cleanup()
{
	printf("CPauseState Cleanup\n");
}

void CPauseState::Pause()
{
	printf("CPauseState Pause\n");
}

void CPauseState::Resume()
{
	printf("CPauseState Resume\n");
}

void CPauseState::HandleEvents(CGameEngine* game)
{
    if(game->receiver.IsKeyPressed(KEY_KEY_P)) {
		game->PopState();
	}
	
	game->receiver.reset();
}

void CPauseState::Update(CGameEngine* game)
{
	
}

void CPauseState::Draw(CGameEngine* game)
{
	int lastFPS = -1;
	
	bool soundplaying = false;	
    
	if(game->device->run()) {
		if (game->device->isWindowActive())
		{
			driver->beginScene(true, true, video::SColor(0,200,200,200));
			
			smgr->drawAll();
			
			int width = 400;
			int height = 150;
				
			driver->draw2DImage(pauseImage, core::position2d<s32>(game->getWidth() /2 - width /2, game->getHeight()/2 - height /2), core::rect<s32>(0, 0, width, height), 0, video::SColor(255,255,255,255), true);

            u32 time = game->device->getTimer()->getTime();
            
//            if (font)
//                font->draw(L"This demo shows that Irrlicht is also capable of drawing 2D graphics.",
//                           core::rect<s32>(10,10,300,100),
//                           video::SColor(255,time % 255,time % 255,255), true, true);
            
			driver->endScene();
			
			int fps = driver->getFPS();
			if (lastFPS != fps)
			{
				core::stringw str = L"Contratempo [";
				str += driver->getName();
				str += "] FPS:";
				str += fps;
				
				game->device->setWindowCaption(str.c_str());
				lastFPS = fps;
			}			
		}
	}
}