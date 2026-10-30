// Data below mirrors the .v files in the project root. conns = { port: expression in the parent }.
const MODULES = {
  testbench: {
    file: 'testbench.v', ports: [],
    regs: [['clk', 1], ['reset', 1]], wires: [['WriteData', 32], ['DataAdr', 32], ['MemWrite', 1]],
    note: 'Generates clk/reset and checks MemWrite writes (addr 100 = 25).',
    children: [{ inst: 'dut', mod: 'top',
      conns: { clk: 'clk', reset: 'reset', WriteData: 'WriteData', DataAdr: 'DataAdr', MemWrite: 'MemWrite' } }]
  },
  top: {
    file: 'top.v',
    ports: [['in','clk',1], ['in','reset',1], ['out','WriteData',32], ['out','DataAdr',32], ['out','MemWrite',1]],
    wires: [['PCF', 32], ['Instr', 32], ['ReadData', 32]],
    children: [
      { inst: 'rvsingle', mod: 'riscvsingle', conns: { clk:'clk', reset:'reset', PC:'PCF', Instr:'Instr',
        MemWrite:'MemWrite', DataAdr:'DataAdr', WriteData:'WriteData', ReadData:'ReadData' } },
      { inst: 'imem', mod: 'imem', conns: { a:'PCF', rd:'Instr' } },
      { inst: 'dmem', mod: 'dmem', conns: { clk:'clk', we:'MemWrite', a:'DataAdr', wd:'WriteData', rd:'ReadData' } }
    ]
  },
  riscvsingle: {
    file: 'riscvsingle.v',
    ports: [['in','clk',1], ['in','reset',1], ['out','PC',32], ['in','Instr',32], ['out','MemWrite',1],
            ['out','DataAdr',32], ['out','WriteData',32], ['in','ReadData',32]],
    wires: [['ALUResult',32], ['ALUSrc',1], ['RegWrite',1], ['Jump',1], ['Zero',1], ['ResultSrc',2],
            ['ImmSrc',2], ['ALUControl',3], ['PCSrc',1]],
    assigns: ['DataAdr = ALUResult'], alias: [['DataAdr', 'ALUResult']],
    children: [
      { inst: 'c', mod: 'controller', conns: { op:'Instr[6:0]', funct3:'Instr[14:12]', funct7b5:'Instr[30]', Zero:'Zero',
        ResultSrc:'ResultSrc', MemWrite:'MemWrite', PCSrc:'PCSrc', ALUSrc:'ALUSrc', RegWrite:'RegWrite',
        Jump:'Jump', ImmSrc:'ImmSrc', ALUControl:'ALUControl' } },
      { inst: 'dp', mod: 'datapath', conns: { clk:'clk', reset:'reset', ResultSrc:'ResultSrc', PCSrc:'PCSrc',
        ALUSrc:'ALUSrc', RegWrite:'RegWrite', ImmSrc:'ImmSrc', ALUControl:'ALUControl', Zero:'Zero', PC:'PC',
        Instr:'Instr', ALUResult:'ALUResult', WriteData:'WriteData', ReadData:'ReadData' } }
    ]
  },
  controller: {
    file: 'controller.v',
    ports: [['in','op',7], ['in','funct3',3], ['in','funct7b5',1], ['in','Zero',1], ['out','ResultSrc',2],
            ['out','MemWrite',1], ['out','PCSrc',1], ['out','ALUSrc',1], ['out','RegWrite',1], ['out','Jump',1],
            ['out','ImmSrc',2], ['out','ALUControl',3]],
    wires: [['ALUOp',2], ['Branch',1]],
    assigns: ['PCSrc = Branch & Zero | Jump'],
    children: [
      { inst: 'md', mod: 'maindec', conns: { op:'op', ResultSrc:'ResultSrc', MemWrite:'MemWrite', Branch:'Branch',
        ALUSrc:'ALUSrc', RegWrite:'RegWrite', Jump:'Jump', ImmSrc:'ImmSrc', ALUOp:'ALUOp' } },
      { inst: 'ad', mod: 'aludec', conns: { opb5:'op[5]', funct3:'funct3', funct7b5:'funct7b5', ALUOp:'ALUOp',
        ALUControl:'ALUControl' } }
    ]
  },
  datapath: {
    file: 'datapath.v', params: 'WIDTH = 32 (localparam)',
    ports: [['in','clk',1], ['in','reset',1], ['in','ResultSrc',2], ['in','PCSrc',1], ['in','ALUSrc',1],
            ['in','RegWrite',1], ['in','ImmSrc',2], ['in','ALUControl',3], ['out','Zero',1], ['out','PC',32],
            ['in','Instr',32], ['out','ALUResult',32], ['out','WriteData',32], ['in','ReadData',32]],
    wires: [['PCNext',32], ['PCPlus4',32], ['PCTarget',32], ['ImmExt',32], ['SrcA',32], ['SrcB',32], ['Result',32]],
    children: [
      { inst: 'pcreg', mod: 'flopr', param: '#(32)', conns: { clk:'clk', reset:'reset', d:'PCNext', q:'PC' } },
      { inst: 'pcadd4', mod: 'adder', conns: { a:'PC', b:'32\'d4', y:'PCPlus4' } },
      { inst: 'pcaddbranch', mod: 'adder', conns: { a:'PC', b:'ImmExt', y:'PCTarget' } },
      { inst: 'pcmux', mod: 'mux2', param: '#(32)', conns: { d0:'PCPlus4', d1:'PCTarget', s:'PCSrc', y:'PCNext' } },
      { inst: 'rf', mod: 'regfile', conns: { clk:'clk', we3:'RegWrite', a1:'Instr[19:15]', a2:'Instr[24:20]',
        a3:'Instr[11:7]', wd3:'Result', rd1:'SrcA', rd2:'WriteData' } },
      { inst: 'ext', mod: 'extend', conns: { instr:'Instr[31:7]', immsrc:'ImmSrc', immext:'ImmExt' } },
      { inst: 'srcbmux', mod: 'mux2', param: '#(32)', conns: { d0:'WriteData', d1:'ImmExt', s:'ALUSrc', y:'SrcB' } },
      { inst: 'alu', mod: 'alu', conns: { a:'SrcA', b:'SrcB', alucontrol:'ALUControl', result:'ALUResult', zero:'Zero' } },
      { inst: 'resultmux', mod: 'mux3', param: '#(32)', conns: { d0:'ALUResult', d1:'ReadData', d2:'PCPlus4',
        s:'ResultSrc', y:'Result' } }
    ]
  },
  // leaf modules
  maindec: { file: 'maindec.v', note: 'opcode → control word (lw, sw, R, beq, I-ALU, jal)',
    ports: [['in','op',7], ['out','ResultSrc',2], ['out','MemWrite',1], ['out','Branch',1], ['out','ALUSrc',1],
            ['out','RegWrite',1], ['out','Jump',1], ['out','ImmSrc',2], ['out','ALUOp',2]] },
  aludec: { file: 'aludec.v', note: 'ALUOp + funct3/funct7b5 → ALUControl',
    ports: [['in','opb5',1], ['in','funct3',3], ['in','funct7b5',1], ['in','ALUOp',2], ['out','ALUControl',3]] },
  alu: { file: 'alu.v', note: 'add, sub, and, or, xor, slt, sll, srl',
    ports: [['in','a',32], ['in','b',32], ['in','alucontrol',3], ['out','result',32], ['out','zero',1]] },
  regfile: { file: 'regfile.v', note: '32 regs, 2 async reads, 1 write on posedge, x0 = 0',
    ports: [['in','clk',1], ['in','we3',1], ['in','a1',5], ['in','a2',5], ['in','a3',5], ['in','wd3',32],
            ['out','rd1',32], ['out','rd2',32]] },
  extend: { file: 'extend.v', note: 'immediate generator (I, S, B, J)',
    ports: [['in','instr',25], ['in','immsrc',2], ['out','immext',32]] },
  adder: { file: 'adder.v', ports: [['in','a',32], ['in','b',32], ['out','y',32]] },
  mux2: { file: 'mux2.v', ports: [['in','d0',0], ['in','d1',0], ['in','s',1], ['out','y',0]] },
  mux3: { file: 'mux3.v', ports: [['in','d0',0], ['in','d1',0], ['in','d2',0], ['in','s',2], ['out','y',0]] },
  flopr: { file: 'flopr.v', note: 'register with async reset',
    ports: [['in','clk',1], ['in','reset',1], ['in','d',0], ['out','q',0]] },
  imem: { file: 'imem.v', note: 'instruction ROM, loads riscvtest.dat',
    ports: [['in','a',32], ['out','rd',32]] },
  dmem: { file: 'dmem.v', note: 'data RAM, write on posedge',
    ports: [['in','clk',1], ['in','we',1], ['in','a',32], ['in','wd',32], ['out','rd',32]] }
};

const NETS = {};              // net id -> [{path, label}]
const el = (tag, cls, text) => { const e = document.createElement(tag); if (cls) e.className = cls; if (text) e.textContent = text; return e; };

function chip(cls, text, net, path, label) {
  const c = el('span', 'chip ' + cls, text);
  if (net) {
    c.dataset.net = net;
    (NETS[net] = NETS[net] || []).push({ path, label });
    c.onclick = () => highlight(net);
  }
  return c;
}

function row(label) { const r = el('div', 'row'); r.appendChild(el('label', '', label)); return r; }

function render(modName, inst, path, portNets, conns, param) {
  const m = MODULES[modName];
  const leaf = !m.children;
  const box = el('div', 'box' + (leaf ? ' leaf' : ''));
  const t = el('div', 'title', inst + ' : ' + modName + (param ? ' ' + param : ''));
  if (m.note) t.appendChild(el('small', '', m.note));
  t.appendChild(el('span', 'file', m.file));
  t.onclick = () => box.classList.toggle('closed');
  box.appendChild(t);
  const body = el('div', 'body');
  box.appendChild(body);

  // net ids: ports come from the parent, wires are born here
  const nets = {};
  (m.ports || []).forEach(([, n]) => nets[n] = portNets[n] || path + '/' + n);
  [...(m.wires || []), ...(m.regs || [])].forEach(([n]) => nets[n] = path + '/' + n);
  (m.alias || []).forEach(([a, b]) => nets[b] = nets[a]);

  if (m.params) body.appendChild(el('div', 'note', 'parameter: ' + m.params));

  if (m.ports && m.ports.length) {
    const r = row('ports');
    m.ports.forEach(([dir, n, w]) => {
      const expr = conns && conns[n];
      const txt = (dir === 'in' ? '▸ ' : '◂ ') + n + (w > 1 ? '[' + (w - 1) + ':0]' : '') + (expr ? ' = ' + expr : '');
      r.appendChild(chip(dir, txt, nets[n], path, n + ' (port)'));
    });
    body.appendChild(r);
  }
  if ((m.wires || []).length || (m.regs || []).length) {
    const r = row('declared');
    (m.regs || []).forEach(([n, w]) => r.appendChild(chip('wire', 'reg ' + n, nets[n], path, n + ' (declared)')));
    (m.wires || []).forEach(([n, w]) => r.appendChild(chip('wire', n + (w > 1 ? '[' + (w - 1) + ':0]' : ''), nets[n], path, n + ' (declared)')));
    body.appendChild(r);
  }
  (m.assigns || []).forEach(a => { const r = row('assign'); r.appendChild(el('span', 'assign', a)); body.appendChild(r); });

  if (m.children) {
    const kids = el('div', 'children');
    m.children.forEach(c => {
      // resolve each parent-side expression to a net (base identifier only; constants have none)
      const childNets = {};
      for (const [port, expr] of Object.entries(c.conns)) {
        const id = (expr.match(/^[A-Za-z_]\w*/) || [])[0];
        if (id && nets[id]) childNets[port] = nets[id];
      }
      kids.appendChild(render(c.mod, c.inst, path + '.' + c.inst, childNets, c.conns, c.param));
    });
    body.appendChild(kids);
  }
  return box;
}

function highlight(net) {
  document.querySelectorAll('.chip.hl').forEach(c => c.classList.remove('hl'));
  document.querySelectorAll('.chip[data-net]').forEach(c => { if (c.dataset.net === net) c.classList.add('hl'); });
  const trace = document.getElementById('trace');
  trace.innerHTML = '';
  (NETS[net] || []).forEach(s => trace.appendChild(el('span', 'step', s.path + ' · ' + s.label)));
}

document.getElementById('root').appendChild(render('testbench', 'testbench', 'testbench', {}, null));
document.getElementById('expand').onclick = () => document.querySelectorAll('.box').forEach(b => b.classList.remove('closed'));
document.getElementById('collapse').onclick = () => document.querySelectorAll('.box.leaf').forEach(b => b.classList.add('closed'));
document.getElementById('collapse').click();
