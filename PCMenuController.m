/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

   Author: Philippe C.D. Robert <probert@siggraph.org>

   This file is part of GNUstep.

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include "PCAppController.h"
#include "PCMenuController.h"
#include <ProjectCenter/ProjectCenter.h>

@implementation PCMenuController

- (id)init
{
  if ((self = [super init])) 
    {
      [[NSNotificationCenter defaultCenter]
	addObserver:self 
	   selector:@selector(editorDidBecomeActive:)
	       name:PCEditorDidBecomeActiveNotification 
	     object:nil];

      [[NSNotificationCenter defaultCenter]
	addObserver:self 
	   selector:@selector(editorDidResignActive:)
	       name:PCEditorDidResignActiveNotification 
	     object:nil];

      editorIsActive = NO;
    }

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [super dealloc];
}

- (void)setAppController:(id)anObject
{
  appController = anObject;
}

- (void)setProjectManager:(id)anObject
{
  projectManager = anObject;
}

//============================================================================
//==== Menu stuff
//============================================================================

// Info
- (void)showPrefWindow:(id)sender
{
  [[[NSApp delegate] prefController] showPrefWindow:sender];
}

- (void)showInfoPanel:(id)sender
{
  [[[NSApp delegate] infoController] showInfoWindow:sender];
}

- (void)showEditorPanel:(id)sender
{
  [[[projectManager activeProject] projectWindow] showProjectEditor:self];
}

// Project
- (void)projectOpen:(id)sender
{
  [projectManager openProject];
}

- (void)projectNew:(id)sender
{
  [projectManager newProject];
}

- (void)projectSave:(id)sender
{
  [projectManager saveProject];
}

- (void)projectAddFiles:(id)sender
{
  [projectManager addProjectFiles];
}

- (void)projectSaveFiles:(id)sender
{
  [projectManager saveProjectFiles];
}

- (void)projectRemoveFiles:(id)sender
{
  [projectManager removeProjectFiles];
}

- (void)projectClose:(id)sender
{
  [projectManager closeProject];
}

// Subproject
- (void)subprojectNew:(id)sender
{
  [projectManager newSubproject];
}

- (void)subprojectAdd:(id)sender
{
  NSString *proj = nil;

  // Show open panel

  [projectManager addSubprojectAt:proj];
}

- (void)subprojectRemove:(id)sender
{
  [projectManager removeSubproject];
}

// File
- (void)fileOpen:(id)sender
{
  [projectManager openFile];
}

- (void)fileNew:(id)sender
{
  [projectManager newFile];
}

- (void)fileSave:(id)sender
{
  [projectManager saveFile];
}

- (void)fileSaveAs:(id)sender
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSSavePanel	 *savePanel = [NSSavePanel savePanel];
  NSString       *oldFilePath = nil;
  NSString 	 *newFilePath = nil;
  NSString       *directory = nil;
  int		 retval = NSOKButton;

  oldFilePath = 
    [[[[projectManager activeProject] projectEditor] activeEditor] path];

  [savePanel setTitle: @"Save As..."];
  while (![directory isEqualToString: [projectManager projectPath]] 
	 && retval != NSCancelButton)
    {
      retval = [savePanel 
	runModalForDirectory:[projectManager projectPath]
	                file:[projectManager selectedFileName]];
      directory = [savePanel directory];
    }

  if (retval == NSOKButton)
    {
      [ud setObject:directory forKey:@"LastOpenDirectory"];

      newFilePath = [savePanel filename];
		  
      if (![projectManager saveFileAs:newFilePath]) 
	{
	  NSRunAlertPanel(@"Attention!",
			  @"Couldn't save file as\n%@!",
			  @"OK",nil,nil,newFilePath);
	}
      else
	{
	  PCProject *project = [projectManager activeProject];
	  NSString  *category =  nil;
	  
	  category = [[project rootEntries] objectForKey:PCNonProject];

	  [projectManager closeFile];
	  [project addFiles:[NSArray arrayWithObject:newFilePath]
	             forKey:PCNonProject];
	  [[project projectEditor] editorForFile:newFilePath
	                                category:category
				        windowed:NO];
	}
    }
}


- (void)fileSaveTo:(id)sender
{
  [projectManager saveFileTo];
}

- (void)fileRevertToSaved:(id)sender
{
  [projectManager revertFileToSaved];
}

- (void)fileClose:(id)sender
{
  [projectManager closeFile];
}

- (void)fileOpenQuickly:(id)sender
{
  NSRunAlertPanel(@"PCMenuController: Sorry!",
		  @"This feature is not finished yet",
		  @"OK",nil,nil);
}

- (void)fileRename:(id)sender
{
  // Show Inspector panel with "File Attributes" section
  [projectManager renameFile];

/*  NSRunAlertPanel(@"PCMenuController: Sorry!",
		  @"This feature is not finished yet",
		  @"OK",nil,nil);*/
}

- (void)fileNewUntitled:(id)sender
{
  NSRunAlertPanel(@"PCMenuController: Sorry!",
		  @"This feature is not finished yet",
		  @"OK",nil,nil);
}

// Edit. PCProjectEditor have to provide this menu and functionality
- (void)findShowPanel:(id)sender
{
  [[PCTextFinder sharedFinder] showFindPanel:self];
}

- (void)findNext:(id)sender
{
  [[PCTextFinder sharedFinder] findNext:self];
}

- (void)findPrevious:(id)sender
{
  [[PCTextFinder sharedFinder] findPrevious:self];
}

// Tools
- (void)showInspector:(id)sender
{
  [projectManager showProjectInspector:self];
}

- (void)showHistoryPanel:(id)sender
{
  [projectManager showProjectHistory:self];
}

- (void)showBuildPanel:(id)sender
{
  [[[projectManager activeProject] projectWindow] showProjectBuild:self];
}

- (void)showLaunchPanel:(id)sender
{
  [[[projectManager activeProject] projectWindow] showProjectLaunch:self];
}

- (void)runTarget:(id)sender
{
  [[projectManager activeProject] runSelectedTarget:self];
}

//============================================================================
//==== Delegate stuff
//============================================================================

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
  NSString    *menuTitle = [[menuItem menu] title];
  PCProject   *aProject = [projectManager activeProject];

  if ([[projectManager loadedProjects] count] == 0) 
    {
      // Project related menu items
      if ([menuTitle isEqualToString: @"Project"])
	{
	  if ([[menuItem title] isEqualToString:@"Save"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save As..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Add Files..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save Files..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Remove Files..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Close"]) return NO;
	}

      // File related menu items
      if ([menuTitle isEqualToString: @"File"])
	{
	  if ([[menuItem title] isEqualToString:@"New in Project"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save As..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save To..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Revert to Saved"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Close"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Open Quickly..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Rename"]) return NO;
	  if ([[menuItem title] isEqualToString:@"New Untitled"]) return NO;
	}

      // Tools menu items
      if ([menuTitle isEqualToString: @"Tools"])
	{
	  if ([[menuItem title] isEqualToString:@"Inspector..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Hide Tool Bar"]) return NO;
	}
      if ([menuTitle isEqualToString: @"Project Build"])
	{
	  if ([[menuItem title] isEqualToString:@"Show Panel..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Build"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Stop Build"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Clean"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Next Error"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Previous Error"]) return NO;
	}
      if ([menuTitle isEqualToString: @"Project Find"])
	{
	  if ([[menuItem title] isEqualToString:@"Show Panel..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Find Preferences"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Find Definitions"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Find Text"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Find Regular Expr"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Next match"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Previous match"]) return NO;
	}
      if ([menuTitle isEqualToString: @"Loaded Files"])
	{
	  if ([[menuItem title] isEqualToString:@"Show Panel..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Sort by Time Viewed"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Sort by Name"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Next File"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Previous File"]) return NO;
	}
      if ([menuTitle isEqualToString: @"Launcher"])
	{
	  if ([[menuItem title] isEqualToString:@"Show Panel..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Run"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Debug"]) return NO;
	}
      if ([menuTitle isEqualToString: @"Indexer"])
	{
	  if ([[menuItem title] isEqualToString:@"Show Panel..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Purge Indices"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Index Subproject"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Index File"]) return NO;
	}
      return YES;
    }

  // Project related menu items
  if ([menuTitle isEqualToString: @"Project"] 
      && [aProject selectedRootCategory] == nil)
    {
      if ([[menuItem title] isEqualToString:@"Add Files..."]) return NO;
      if ([[menuItem title] isEqualToString:@"Remove Files..."]) return NO;
    }

  // File related menu items
  if (([menuTitle isEqualToString: @"File"]))
    {
      if (!editorIsActive)
	{
	  if ([[menuItem title] isEqualToString:@"Save"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save As..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save To..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Revert to Saved"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Close"]) return NO;
	}
    }
  if ([[aProject projectBrowser] nameOfSelectedFile] == nil)
    {
      if ([[menuItem title] isEqualToString:@"Rename"]) return NO;
    }

  // Find menu items
  if (editorIsActive == NO && [menuTitle isEqualToString: @"Find"])
    {
      if (![[[PCTextFinder sharedFinder] findPanel] isVisible])
	{
	  if ([[menuItem title] isEqualToString:@"Find Next"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Find Previous"]) return NO;
	}
      if ([[menuItem title] isEqualToString:@"Enter Selection"]) return NO;
      if ([[menuItem title] isEqualToString:@"Jump to Selection"]) return NO;
      if ([[menuItem title] isEqualToString:@"Line Number..."]) return NO;
      if ([[menuItem title] isEqualToString:@"Man Page"]) return NO;
    }

  return YES;
}

- (void)editorDidResignActive:(NSNotification *)aNotif
{
  editorIsActive = NO;
}

- (void)editorDidBecomeActive:(NSNotification *)aNotif
{
  editorIsActive = YES;
}

@end

