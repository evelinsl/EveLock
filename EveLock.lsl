///
/// evelin (evilevelin)'s RLV lock script, v1.0
///
/// You are free to use this script for personal items.
/// You are NOT allowed to sell items with this script in it.
///
/// You can edit the value of "type" to change it to
/// whatever it is you place this script it.
///  


string type = "corset belt";

integer locked = FALSE;
key ownerKey = NULL_KEY;

key dialogUser = NULL_KEY;
integer dialogListenHandler;
integer dialogChannel;

string DIALOG_LOCK = "Lock";
string DIALOG_UNLOCK = "Unlock";
string DIALOG_TAKE_KEY = "Take the key";
string DIALOG_LEAVE_THE_KEY = "Leave key";
string DIALOG_EXIT = "Close";


///
/// Debug function to report the current lock state, not used atm
///
reportState()
{
    string lockState = "locked";
    if(locked == FALSE)
        lockState = "unlocked";
        
    llSay(0, llGetDisplayName(llGetOwner()) + " " + type + " is " + lockState);
}


///
/// Shows the menu and the current state 
///
showMenu()
{
    string wearer = llGetDisplayName(llGetOwner());
    string owner = "(nobody)";
    string lockState = "No";
    
    if(locked)
        lockState = "Yes";
    
    if(isOwned())
        owner = llGetDisplayName(ownerKey);
    
    string message = "evelin's " + type + " locker\n\n";
    message += "Worn by: " + wearer + "\n";
    message += "Locked: " + lockState + "\n";
    message += "Key holder: " + owner + "\n";
    
    llDialog(dialogUser, message, getMenuButtons(), dialogChannel);
}


///
/// Returns positive if the item has an owner
///
integer isOwned()
{
    return ownerKey != NULL_KEY;
}


///
/// Returns positive if the current dialog user is also the owner
///
integer currentUserIsOwner()
{
    return isOwned() && dialogUser == ownerKey;
}


///
/// Creates a list of buttons to be displayed on the menu.
/// Buttons will be visible based on certain states.
///
list getMenuButtons()
{
    list keys = [];
    
    if(locked == TRUE)
        keys = keys + [DIALOG_UNLOCK];
    else
        keys = keys + [DIALOG_LOCK];
        
    // The owner can return the key    
    
    if(isOwned() && dialogUser == ownerKey)
        keys = keys + [DIALOG_LEAVE_THE_KEY];

    if(!isOwned())
        keys = keys + [DIALOG_TAKE_KEY];  
        
    keys += [DIALOG_EXIT];
        
    return keys;
}


///
/// Unlocks the item.
/// If there is an owner, then only the owner can operate the lock button.
///
unlock()
{ 
    // Lets see if the dialog user is the owner
    
    if(isOwned() && !currentUserIsOwner())
    {
        llSay(0, "You cannot unlock this " + type + " because you are not the owner of it.");   
        return;
    }
    
    locked = FALSE;
    llOwnerSay("@detach=y");
    
    llSay(0, llGetDisplayName(llGetOwner()) + "'s " + type + " is now unlocked.");
}


///
/// Locks the item.
/// If there is an owner, then only the owner can operate the lock button.
///
lock()
{
    if(isOwned() && !currentUserIsOwner())
    {
        llSay(0, "You cannot lock this " + type + " because you are not the owner of it.");   
        return;
    }
    
    locked = TRUE;
    llOwnerSay("@detach=n");
    
    llSay(0, llGetDisplayName(llGetOwner()) + "'s " + type + " is now locked!");
}


///
/// Lets the current owner return the key
///
leaveKey()
{
    if(!currentUserIsOwner())
    {
        llSay(0, "You cannot leave a key if you are not the owner");   
        return;   
    }
    
    llSay(0, llGetDisplayName(ownerKey) + " left the key on " +  llGetDisplayName(llGetOwner()) + "'s " + type + ".");
    ownerKey = NULL_KEY;
}


///
/// Let the current user become the owner, if the key is available
///
takeKeys()
{
    if(isOwned())
    {
        llSay(0, "You cannot take the keys of this " + type);   
        return;
    }
    
    ownerKey = dialogUser;
    llSay(0, llGetDisplayName(ownerKey) + " is now the owner of " + llGetDisplayName(llGetOwner()) + "'s " + type + ".");
}

///
/// Unsets the current dialog user
///
freeDialog()
{
    llSetTimerEvent(0);
    dialogUser = NULL_KEY;
}


default
{
    
    state_entry()
    {   
        dialogChannel = -1 - (integer)("0x" + llGetSubString((string)llGetKey(), -7, -1));
        dialogListenHandler = llListen(dialogChannel, "", llGetOwner(), ""); 
    }
    

    touch_start(integer total_number)
    {
        if(dialogUser != NULL_KEY && dialogUser != llDetectedKey(0))
        {
            llSay(0,  llGetDisplayName( llDetectedKey(0)) + " is using the menu, please wait");
            return;
        }
    
        dialogUser = llDetectedKey(0);
        
        llSetTimerEvent(30);
        llListen(dialogChannel, "", dialogUser, "");
        
        showMenu();
    }
    
    
    timer()
    {
        llSetTimerEvent(0);
        llSay(PUBLIC_CHANNEL, "Timeout");
        dialogUser = NULL_KEY;
    }
    
        
    listen(integer channel, string name, key id, string message)
    {
        if(channel != dialogChannel)
            return;

        if(message == DIALOG_LOCK)
        {
            lock();
            
        } else if(message == DIALOG_UNLOCK)
        {
            unlock();
            
        } else if(message == DIALOG_TAKE_KEY)
        {
            takeKeys();
            
        } else if(message == DIALOG_LEAVE_THE_KEY)
        {
            leaveKey();
        }
        
        freeDialog();
    }
    
}
