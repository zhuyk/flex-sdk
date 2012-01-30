////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2010 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package spark.components.supportClasses
{
import flash.desktop.NativeApplication;
import flash.display.StageOrientation;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.StageOrientationEvent;
import flash.system.Capabilities;
import flash.ui.Keyboard;

import mx.events.FlexEvent;

import spark.components.Application;
import spark.core.managers.IPersistenceManager;
import spark.core.managers.PersistenceManager;

[Exclude(name="controlBarContent", kind="property")]
[Exclude(name="controlBarGroup", kind="property")]
[Exclude(name="controlBarLayout", kind="property")]
[Exclude(name="controlBarVisible", kind="property")]
[Exclude(name="layout", kind="property")]
[Exclude(name="preloaderChromeColor", kind="property")] // TODO (chiedozi): Check this
[Exclude(name="rollOverColor", kind="style")]   // TODO (chiedozi): Check this
[Exclude(name="backgroundAlpha", kind="style")] // TODO (chiedozi): Check this

//--------------------------------------
//  Events
//--------------------------------------

/**
 *  @inheritDoc
 */
[Event(name="applicationPersist", type="mx.events.FlexEvent")]

/**
 *  @inheritDoc
 */
[Event(name="applicationPersisting", type="mx.events.FlexEvent")]

/**
 *  @inheritDoc
 */
[Event(name="applicationRestore", type="mx.events.FlexEvent")]

/**
 *  @inheritDoc
 */
[Event(name="applicationRestoring", type="mx.events.FlexEvent")]

/**
 * 
 */
public class MobileApplicationBase extends Application
{
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------
    /**
     *
     */ 
    public function MobileApplicationBase()
    {
        super();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  persistenceManager
    //----------------------------------
    private var _persistenceManager:IPersistenceManager;
    
    /**
     *  
     */
    public function get persistenceManager():IPersistenceManager
    {
        return _persistenceManager;
    }
    /**
     *  @private
     */
    public function set persistenceManager(value:IPersistenceManager):void
    {
        if (value == _persistenceManager)
            return;
        
        if (_persistenceManager && _persistenceManager.enabled)
        {
            _persistenceManager.flush();
            _persistenceManager.enabled = false;
        }
        
        _persistenceManager = value;
    }
    
    //----------------------------------
    //  sessionCachingEnabled
    //----------------------------------
    
    private var _sessionCachingEnabled:Boolean = false;
    
    /**
     *  
     */
    public function get sessionCachingEnabled():Boolean
    {
        return _sessionCachingEnabled;
    }
    /**
     * @private
     */ 
    public function set sessionCachingEnabled(value:Boolean):void
    {
        _sessionCachingEnabled = value;
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
    /**
     *
     */ 
    protected function addApplicationListeners():void
    {
        // Add device event listeners
        systemManager.stage.addEventListener(KeyboardEvent.KEY_DOWN, deviceKeyDownHandler);
        systemManager.stage.addEventListener(KeyboardEvent.KEY_UP, deviceKeyUpHandler);
        systemManager.stage.addEventListener(StageOrientationEvent.ORIENTATION_CHANGE, 
                                             orientationChangeHandler);
        
        // Add application deactivate and activate listeners
        NativeApplication.nativeApplication.
            addEventListener(Event.ACTIVATE, applicationActivateHandler);
        
        // We need to listen to different events on desktop and mobile because
        // on desktop, the deactivate event is dispatched whenever the window loses
        // focus.  This could cause persistence to run when the developer doesn't
        // expect it to on desktop.
        var os:String = Capabilities.os;
        
        if (os.indexOf("Windows") != -1 || os.indexOf("Mac OS") != -1)
            NativeApplication.nativeApplication.
                addEventListener(Event.EXITING, applicationDeactivateHandler);
        else
            NativeApplication.nativeApplication.
                addEventListener(Event.DEACTIVATE, applicationDeactivateHandler);
    }
     
    /**
     *
     */ 
    protected function applicationActivateHandler(event:Event):void
    {
    }
    
    /**
     *
     */ 
    protected function applicationDeactivateHandler(event:Event):void
    {
        if (sessionCachingEnabled)
        {
            // Dispatch event for saving persistence data
            var eventDispatched:Boolean = true;
            if (hasEventListener(FlexEvent.APPLICATION_PERSISTING))
                eventDispatched = dispatchEvent(new FlexEvent(FlexEvent.APPLICATION_PERSISTING, 
                                                                false, true));
            
            // TODO (chiedozi): Rename eventDispatched
            if (eventDispatched)
            {
                persistApplicationState();
                persistenceManager.flush();
                
                if (hasEventListener(FlexEvent.APPLICATION_PERSIST))
                    dispatchEvent(new FlexEvent(FlexEvent.APPLICATION_PERSIST));
            }
        }
    }
    
    /**
     *
     */ 
    protected function backKeyHandler():void
    {
        
    }
    
    /**
     *
     */ 
    public function canCancelDefaultBackKeyBehavior():Boolean
    {
        return false;   
    }
    
    /**
     *  @private
     */
    // FIXME (chiedozi): Maybe use a singleton for persistence, PARB (GLENN)
    protected function createPersistenceManager():IPersistenceManager
    {
        return new PersistenceManager();
    }
    
    /**
     *
     */ 
    protected function orientationChangeHandler(event:StageOrientationEvent):void
    {
    }  
    
    /**
     *
     */ 
    protected function persistApplicationState():void
    {
        // Save version number of application
        var appDescriptor:XML = NativeApplication.nativeApplication.applicationDescriptor;
        var ns:Namespace = appDescriptor.namespace();
        
        // TODO (chiedozi): See if reserving these keys is bad
        persistenceManager.setProperty("timestamp", new Date().getMilliseconds());
        persistenceManager.setProperty("applicationVersion", 
                                        appDescriptor.ns::versionNumber.toString());
    }
    
    /**
     *
     */ 
    protected function registerPeristenceClassAliases():void
    {
    }
    
    /**
     *
     */ 
    protected function restoreApplicationState():void
    {
    }
    
    /**
     *
     */ 
    // TODO (chiedozi): Do we need to support unknown orientation?
    public function get landscapeOrientation():Boolean
    {
        return systemManager.stage.deviceOrientation == StageOrientation.ROTATED_LEFT ||
            systemManager.stage.deviceOrientation == StageOrientation.ROTATED_RIGHT;
    }
    
    /**
     *
     */ 
    protected function deviceKeyDownHandler(event:KeyboardEvent):void
    {
        var key:uint = event.keyCode;
        
        // We want to prevent the default down behavior for back key if 
        // the navigator has a view to pop back to
        if (key == Keyboard.BACK && canCancelDefaultBackKeyBehavior())
            event.preventDefault();
    }
    
    /**
     *
     */ 
    protected function deviceKeyUpHandler(event:KeyboardEvent):void
    {
        var key:uint = event.keyCode;
        
        if (key == Keyboard.BACK && canCancelDefaultBackKeyBehavior())
            backKeyHandler();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Overridden methods: UIComponent
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private 
     */ 
    override public function initialize():void
    {
        super.initialize();
        
        addApplicationListeners();
        
        if (sessionCachingEnabled)
        {
            registerPeristenceClassAliases();
            
            persistenceManager = createPersistenceManager();
            persistenceManager.initialize();
            
            // Dispatch event for loading persistence data
            var eventDispatched:Boolean = true;
            if (hasEventListener(FlexEvent.APPLICATION_RESTORING))
                eventDispatched = dispatchEvent(new FlexEvent(FlexEvent.APPLICATION_RESTORING, 
                                                false, true));
            
            if (eventDispatched)
            {
                restoreApplicationState();
                
                if (hasEventListener(FlexEvent.APPLICATION_RESTORE))
                    eventDispatched = dispatchEvent(new FlexEvent(FlexEvent.APPLICATION_RESTORE));
            }
        } 
    }
}
}







