/*
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */
package net.sf.l2j.gameserver.handler.voicedcommandhandlers;

import net.sf.l2j.gameserver.handler.IVoicedCommandHandler;
import net.sf.l2j.gameserver.model.actor.instance.L2PcInstance;
import net.sf.l2j.gameserver.model.events.Korean;

public class KoreanCommands implements IVoicedCommandHandler
{
	private static final String[] _voicedCommands =
	{
		"joinkr",
		"leavekr"
	};
	
	/**
	 * 
	 * @see net.sf.l2j.gameserver.handler.IVoicedCommandHandler#useVoicedCommand(java.lang.String, net.sf.l2j.gameserver.model.actor.instance.L2PcInstance, java.lang.String)
	 */
	public boolean useVoicedCommand(String command, L2PcInstance activeChar, String target)
	{
		if (!Korean.getInstance().state.equals(Korean.State.REGISTER))
		{
			activeChar.sendMessage("Korean Event Registration is currently closed.");
			return false;
		}
		if (command.equalsIgnoreCase("joinkr"))
        {
			Korean.getInstance().register(activeChar);
        }
        else if (command.equalsIgnoreCase("leavekr"))
        {
        	Korean.getInstance().unregister(activeChar);
        }
		return true;
	}
	
	/**
	 * 
	 * @see net.sf.l2j.gameserver.handler.IVoicedCommandHandler#getVoicedCommandList()
	 */
	public String[] getVoicedCommandList()
	{
		return _voicedCommands;
	}
}