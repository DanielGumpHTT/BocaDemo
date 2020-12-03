///////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  BocaIpadSDK.h
//  BocaIpadSDK
//
//  Created by Michael Hall on 10/15/16.
//  Copyright © 2016 Boca Systems. All rights reserved.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>


@interface BocaIpadSDK : NSObject

//Start or end a wi-fi session
BOOL OpenSessionWiFi(NSString *ip);
void CloseSessionWiFi(void);

//Start or end a Bluetooth session
BOOL OpenSessionBT(void);
BOOL OpenSessionBTPicker(NSString *name);
void CloseSessionBT(void);

//Start or end a USB/Lightning session
BOOL OpenSessionUSB(void);
void CloseSessionUSB(void);

//Alter printer configuration items from their default values
void ChangeConfiguration(NSString *path, int resolution, bool scaled, bool dithered, int stocksizeindex, NSString *orientation);

//Send string to the printer.  This can be character data to be printed on the ticket or it can be FGL commands to be executed by the printer
void SendString(NSString *string);

//Send a file to the printer for printing.  Supported file formats include suffix *.txt, *.bmp, *.png, *.jpg, *.jpeg and *.pdf
//When transmitting a text file the row and column parameters will not be used.  With any of the other file they will be used for positioning
bool SendFile(NSURL *filename, int row, int column);

//Send an image file to the printer to be stored in user space as a logo.  Supported file formats include suffix *.bmp, *.png, *.jpg, *.jpeg and *.pdf
bool DownloadLogo(NSURL *filename, int idnum);

//Print a previously downloaded logo
//When printing a logo on a ticket, the row and column parameters will be used for positioning.
bool PrintLogo(int idnum, int row, int column);

//Clear user space memory
void ClearMemory(void);

//Force printer to eject ticket with printed material (data, text and images) including cutting the ticket
void PrintCut(void);

//Force printer to eject ticket with printed material (data, text and images) without cutting the ticket
void PrintNoCut(void);

//Read status back from printer in the form of a string
NSString *ReadPrinter(void);

@end





