// The data object every component passes around: one write or one read.
class fifo_transaction #(parameter int DATA_WIDTH = 32);

  typedef enum { WRITE, READ } kind_e;

  rand kind_e                 kind;
  rand logic [DATA_WIDTH-1:0] data;
  rand int unsigned           delay;

  bit                         saw_full;
  bit                         saw_empty;

  constraint c_delay { delay inside {[0:3]}; }

  function new();
  endfunction

  function fifo_transaction #(DATA_WIDTH) copy();
    copy       = new();
    copy.kind  = this.kind;
    copy.data  = this.data;
    copy.delay = this.delay;
    copy.saw_full  = this.saw_full;
    copy.saw_empty = this.saw_empty;
  endfunction

  function bit compare(fifo_transaction #(DATA_WIDTH) t);
    return (this.data === t.data);
  endfunction

  function string convert2str();
    return $sformatf("kind=%-5s data=0x%0h delay=%0d saw_full=%0b saw_empty=%0b",
                     kind.name(), data, delay, saw_full, saw_empty);
  endfunction

endclass
