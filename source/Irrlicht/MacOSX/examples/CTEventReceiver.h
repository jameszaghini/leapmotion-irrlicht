//
//  CTEventReceiver.h
//  Contratempo
//
//  Created by James Zaghini on 27/12/12.
//
//

#ifndef __Contratempo__CTEventReceiver__
#define __Contratempo__CTEventReceiver__

#include <irrlicht.h>
#include <iostream>

using namespace irr;

class CTEventReceiver : public IEventReceiver
{
public:

	struct SMouseState
	{
		core::position2di Position;
		bool LeftButtonDown;
		bool LeftButtonPressed;
        bool RightButtonDown;
		bool RightButtonPressed;
	} MouseState;
	
	void reset() {
		if(MouseState.LeftButtonPressed) {
			MouseState.LeftButtonPressed = false;
		}
		if(MouseState.RightButtonPressed) {
			MouseState.RightButtonPressed = false;
		}
		for (u32 i=0; i<KEY_KEY_CODES_COUNT; ++i) {
			KeyIsPressed[i] = false;
		}		
	}
	
    virtual bool OnEvent(const SEvent& event)
	{
		if (event.EventType == irr::EET_MOUSE_INPUT_EVENT)
		{		
			switch(event.MouseInput.Event)
			{
				case EMIE_LMOUSE_PRESSED_DOWN:
					if(!MouseState.LeftButtonDown) {
						MouseState.LeftButtonPressed = true;
					} else {
						MouseState.LeftButtonPressed = false;
						MouseState.LeftButtonDown = true;
					}
					break;
				case EMIE_LMOUSE_LEFT_UP:
					MouseState.LeftButtonDown = false;
					MouseState.LeftButtonPressed = false;
					break;
				case EMIE_RMOUSE_PRESSED_DOWN:
					if(!MouseState.RightButtonDown) {
						MouseState.RightButtonPressed = true;
					} else {
						MouseState.RightButtonPressed = false;
						MouseState.RightButtonDown = true;
					}
                    break;
                case EMIE_RMOUSE_LEFT_UP:
                    MouseState.RightButtonDown = false;
					MouseState.RightButtonPressed = false;
                    break;
				case EMIE_MOUSE_MOVED:
					MouseState.Position.X = event.MouseInput.X;
					MouseState.Position.Y = event.MouseInput.Y;
					break;
					
				default:
					// We won't use the wheel
					break;
			}
		}
        
        if (event.EventType == irr::EET_KEY_INPUT_EVENT) {
			if(!IsKeyDown(event.KeyInput.Key)) {
				KeyIsPressed[event.KeyInput.Key] = true;
			} else {
				KeyIsDown[event.KeyInput.Key] = true;
				KeyIsPressed[event.KeyInput.Key] = false;
			}
			KeyIsDown[event.KeyInput.Key] = event.KeyInput.PressedDown;
		}
		
		return false;
	}
    
	virtual bool IsKeyPressed(EKEY_CODE keyCode) const
	{
		return KeyIsPressed[keyCode];
	}
	
    virtual bool IsKeyDown(EKEY_CODE keyCode) const
    {
        return KeyIsDown[keyCode];
    }	
	
	const SMouseState & GetMouseState(void) const
	{
		return MouseState;
	}	
	
	CTEventReceiver()
	{
        for (u32 i=0; i<KEY_KEY_CODES_COUNT; ++i) {
			KeyIsDown[i] = false;
			KeyIsPressed[i] = false;
		}
	}
	
private:
	bool KeyIsDown[KEY_KEY_CODES_COUNT];
	bool KeyIsPressed[KEY_KEY_CODES_COUNT];
};

#endif /* defined(__Contratempo__CTEventReceiver__) */
