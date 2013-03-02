//
//  CTGameEngine.h
//  Contratempo
//
//  Created by James Zaghini on 30/12/12.
//
//

#ifndef __Contratempo__CTGameEngine__
#define __Contratempo__CTGameEngine__

#include <vector>
#include "irrlicht.h"
#include "CTEventReceiver.h"

using namespace irr;
using namespace core;
using namespace video;
using namespace scene;

class CGameState;

class CGameEngine
{
public:
	
	void Init(const char* title, int width=640, int height=480, int bpp=0, bool fullscreen=false);
	void Cleanup();
	
	void ChangeState(CGameState* state);
	void PushState(CGameState* state);
	void PopState();
	
	void HandleEvents();
	void Update();
	void Draw();
	
	bool Running() { return m_running; }
	void Quit() { m_running = false; }
    
    int getWidth() { return m_width; }
    int getHeight() { return m_height; }
    
    IrrlichtDevice* device;
    CTEventReceiver receiver;
    
private:
	// the stack of states
	std::vector<CGameState*> states;
	
	bool m_running;
	bool m_fullscreen;
    
    int m_width;
    int m_height;
    
};

#endif /* defined(__Contratempo__CTGameEngine__) */
