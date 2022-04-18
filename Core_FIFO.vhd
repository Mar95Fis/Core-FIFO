/* Simple VHDL code for a Core FIFO     	*/
/* FIFO_WIDTH = width of the FIFO data.		*/
/* FIFO_DEPTH = depth of the FIFO.		*/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Core_FIFO is
  Generic(
    FIFO_WIDTH : integer;
    FIFO_DEPTH : integer
  );
  Port(
    clk                 : in std_logic;
    rstn                : in std_logic;
    wr_en               : in std_logic;
    din                 : in std_logic_vector(FIFO_WIDTH-1 downto 0);
    rd_en               : in std_logic;
    dout                : out std_logic_vector(FIFO_WIDTH-1 downto 0);
    empty               : out std_logic;
    full                : out std_logic;
    overflow            : out std_logic;
    underflow           : out std_logic
  );
end entity;

architecture behaviour of Core_FIFO is

signal wr_pointer : integer range 0 to FIFO_DEPTH-1;
signal rd_pointer : integer range 0 to FIFO_DEPTH-1;
type FIFO_BUFFER_type is array(FIFO_DEPTH-1 downto 0) of std_logic_vector(FIFO_WIDTH-1 downto 0);
signal FIFO_BUFFER : FIFO_BUFFER_type;
signal data_counter_in_fifo : integer;

begin


main_process : process(clk, rstn)
begin
  if(rstn = '0')then
    wr_pointer <= 0;
    rd_pointer <= 0;
    dout       <= (others => '0');
    empty      <= '1';
    full       <= '0';
    overflow   <= '0';
    underflow  <= '0';
    data_counter_in_fifo <= 0;
    FIFO_BUFFER <= (others => (others => '0'));
  elsif(rising_edge(clk))then
    overflow   <= '0';
    underflow  <= '0';
    --manage the empty flag
    if(data_counter_in_fifo /= 0)then
      empty <= '0';
    else
      empty <= '1';
    end if;
    --manage the full flag
    if(data_counter_in_fifo = FIFO_DEPTH)then
      full <= '1';
    else
      full <= '0':
    end if;
    --Write request managed if fifo not full
    if(wr_en = '1' and data_counter_in_fifo /= FIFO_DEPTH)then
      --save the data in FIFO
      FIFO_BUFFER(wr_pointer) <= din;
      --manage the write pointer
      if(wr_pointer = FIFO_DEPTH-1)then
	wr_pointer <= 0;
      else
	wr_pointer <= wr_pointer + 1;
      end if;
      if(rd_en = '0' or (rd_en = '1' and data_counter_in_fifo = 0))then	--if we are not reading on the same clock cycle, or if we are reading an empty FIFO, increase the counter of data in FIFO
	data_counter_in_fifo <= data_counter_in_fifo + 1;
      end if;
      --if full, raise the overflow signal
    elsif(wr_en = '1' and data_counter_in_fifo = FIFO_DEPTH)then
      overflow <= '1';
    end if;
    --Read request managed if the FIFO is not empty
    if(rd_en = '1' and data_counter_in_fifo /= 0)then
	  --read the data from the buffer
	  dout <= FIFO_BUFFER(rd_pointer);
	  --manage the read pointer
	  if(rd_pointer = FIFO_DEPTH-1)then
	    rd_pointer <= 0;
	  else
	    rd_pointer <= rd_pointer + 1;
	  end if;
	  if(wr_en = '0' or (wr_en = '1' and data_counter_in_fifo = FIFO_DEPTH))then	--if we are not writing on the same clock cycle or we are writing a full FIFO, decrese the counter of data
	    data_counter_in_fifo <= data_counter_in_fifo - 1;
	  end if;
    --optherwise raise the underflow signal
    elsif(rd_en = '1' and data_counter_in_fifo /= 0)then
          underflow <= '1';
    end if;
  end if;
end process;

end behaviour;
