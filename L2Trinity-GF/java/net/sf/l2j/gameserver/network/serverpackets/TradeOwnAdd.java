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
package net.sf.l2j.gameserver.network.serverpackets;

import net.sf.l2j.gameserver.model.TradeList;
import net.sf.l2j.gameserver.templates.item.L2Item;

/**
 * This class ...
 *
 * @author Yme
 * @version $Revision: 1.2.2.1.2.3 $ $Date: 2005/03/27 15:29:39 $
 */
public final class TradeOwnAdd extends L2GameServerPacket
{
private static final String _S__30_TRADEOWNADD = "[S] 1a TradeOwnAdd";
private final TradeList.TradeItem _item;

public TradeOwnAdd(TradeList.TradeItem item)
{
	_item = item;
}

@Override
protected final void writeImpl()
{
	writeC(0x1a);
	
	writeH(1);  // itens added count
	
	writeH(_item.getItem().getType1()); // item type1
	writeD(_item.getObjectId());
	writeD(_item.getItem().getItemId());
	writeQ(_item.getCount());
	
	int type2 = _item.getItem().getType2();
	int bodyPart = _item.getItem().getBodyPart();
	
	if (bodyPart == L2Item.SLOT_BELT)
		type2 = L2Item.TYPE2_ACCESSORY;
	else if (_item.getItem().getItemId() == 20325) //plastic hair
		type2 = L2Item.TYPE2_ACCESSORY;
	
	writeH(type2);	// item type2
	writeH(0x00);	// ?
	
	writeD(bodyPart);	// rev 415  slot    0006-lr.ear  0008-neck  0030-lr.finger  0040-head  0080-??  0100-l.hand  0200-gloves  0400-chest  0800-pants  1000-feet  2000-??  4000-r.hand  8000-r.hand
	writeH(_item.getEnchant());	// enchant level
	writeH(0x00);
	writeH(_item.getCustomType2());
	
	// T1
	writeH(_item.getAttackElementType());
	writeH(_item.getAttackElementPower());
	for (byte i = 0; i < 6; i++)
	{
		writeH(_item.getElementDefAttr(i));
	}
}

/* (non-Javadoc)
 * @see net.sf.l2j.gameserver.serverpackets.ServerBasePacket#getType()
 */
@Override
public String getType()
{
	return _S__30_TRADEOWNADD;
}

}
