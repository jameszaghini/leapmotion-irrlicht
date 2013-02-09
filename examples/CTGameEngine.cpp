//
//  CTGameEngine.cpp
//  Contratempo
//
//  Created by James Zaghini on 30/12/12.
//
//


#include <stdio.h>
#include "CTGameEngine.h"
#include "CTGameState.h"

using namespace irr;
using namespace core;
using namespace video;
using namespace scene;

void CGameEngine::Init(const char* title, int width, int height, int bpp, bool fullscreen)
{
	int flags = 0;

	m_running = true;
    m_width = width;
    m_height = height;
    
	printf("CGameEngine Init\n");
    
	dimension2d<u32> dimensions = dimension2d<u32>(width, height);
	
	// create device and exit if creation failed
	device = createDevice(EDT_OPENGL, dimensions, bpp, fullscreen, false, false, &receiver);
	
	device->getCursorControl()->setVisible(false);
}

void CGameEngine::Cleanup()
{
	// cleanup the all states
	while ( !states.empty() ) {
		states.back()->Cleanup();
		states.pop_back();
	}
	
	printf("CGameEngine Cleanup\n");
}

void CGameEngine::ChangeState(CGameState* state)
{
	// cleanup the current state
	if ( !states.empty() ) {
		states.back()->Cleanup();
		states.pop_back();
	}
	
	// store and init the new state
	states.push_back(state);
	states.back()->Init(this);
}

void CGameEngine::PushState(CGameState* state)
{
	// pause current state
	if ( !states.empty() ) {
		states.back()->Pause();
	}
	
	// store and init the new state
	states.push_back(state);
	states.back()->Init(this);
}

void CGameEngine::PopState()
{
	// cleanup the current state
	if ( !states.empty() ) {
		states.back()->Cleanup();
		states.pop_back();
	}
	
	// resume previous state
	if ( !states.empty() ) {
		states.back()->Resume();
	}
}


void CGameEngine::HandleEvents()
{
	// let the state handle events
	states.back()->HandleEvents(this);
}

void CGameEngine::Update()
{
	// let the state update the game
	states.back()->Update(this);
}

void CGameEngine::Draw()
{
	// let the state draw the screen
	states.back()->Draw(this);
}
