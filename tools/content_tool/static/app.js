
const state = { schema:null, typeOrder:[], data:{}, type:"cards", current:null };

const $ = s => document.querySelector(s);
const status = (msg, good=true) => {
  $("#statusBar").textContent = msg;
  $("#statusBar").style.color = good ? "#b9d4b8" : "#ff9fa7";
};

async function api(url, options={}){
  const res = await fetch(url, {headers:{"Content-Type":"application/json"}, ...options});
  const text = await res.text();
  let data;
  try { data = text ? JSON.parse(text) : {}; } catch { data={error:text}; }
  if(!res.ok) throw new Error(data.error || (data.errors||[]).join("\n") || `HTTP ${res.status}`);
  return data;
}

function defaultItem(type){
  const item = {};
  for(const f of state.schema[type].fields){
    if(f.default !== undefined) item[f.key] = structuredClone(f.default);
    else if(f.kind === "bool") item[f.key] = false;
    else if(f.kind === "number") item[f.key] = 0;
    else if(f.kind === "json") item[f.key] = Array.isArray(f.default) ? [] : {};
    else item[f.key] = "";
  }
  return item;
}

function renderTabs(){
  const tabs = $("#tabs");
  tabs.innerHTML = "";
  for(const t of state.typeOrder){
    const b = document.createElement("button");
    b.className = "tab" + (t===state.type ? " active":"");
    b.textContent = `${state.schema[t].label} (${(state.data[t]||[]).length})`;
    b.onclick = () => {
      state.type = t; state.current = null;
      renderAll();
    };
    tabs.appendChild(b);
  }
}

function controlFor(field, value){
  let el;
  if(field.kind === "select"){
    el = document.createElement("select");
    for(const opt of field.options||[]){
      const o=document.createElement("option");
      o.value=opt; o.textContent=opt;
      if(String(value)===String(opt)) o.selected=true;
      el.appendChild(o);
    }
  } else if(field.kind === "textarea" || field.kind === "json"){
    el=document.createElement("textarea");
    el.value = field.kind==="json" ? JSON.stringify(value ?? field.default ?? [], null, 2) : (value ?? "");
  } else if(field.kind === "bool"){
    const wrap=document.createElement("div");
    wrap.className="checkbox-row";
    el=document.createElement("input");
    el.type="checkbox"; el.checked=Boolean(value);
    const tx=document.createElement("span"); tx.textContent=field.label;
    wrap.append(el,tx);
    wrap.dataset.key=field.key;
    return wrap;
  } else {
    el=document.createElement("input");
    el.type = field.kind==="number" ? "number":"text";
    el.value = value ?? "";
    if(field.placeholder) el.placeholder=field.placeholder;
  }
  el.dataset.key=field.key;
  el.dataset.kind=field.kind;
  return el;
}

function renderForm(){
  const form=$("#form");
  form.innerHTML="";
  const item = state.current || defaultItem(state.type);
  $("#typeTitle").textContent = state.schema[state.type].label;
  for(const f of state.schema[state.type].fields){
    const wrap=document.createElement("div");
    wrap.className="field";
    if(f.kind !== "bool"){
      const lab=document.createElement("label");
      lab.textContent=f.label;
      wrap.appendChild(lab);
    }
    const c=controlFor(f,item[f.key]);
    wrap.appendChild(c);
    form.appendChild(wrap);
  }
  form.oninput = renderPreview;
  renderPreview();
}

function readForm(){
  const item=structuredClone(state.current || {});
  for(const f of state.schema[state.type].fields){
    let el = $("#form").querySelector(`[data-key="${CSS.escape(f.key)}"]`);
    if(f.kind==="bool"){
      if(el && el.classList.contains("checkbox-row")) el=el.querySelector("input");
      item[f.key]=Boolean(el?.checked);
    } else if(f.kind==="number"){
      item[f.key]=Number(el?.value||0);
    } else if(f.kind==="json"){
      const raw=(el?.value||"").trim();
      item[f.key]=raw ? JSON.parse(raw) : (Array.isArray(f.default)?[]:{});
    } else {
      item[f.key]=el?.value ?? "";
    }
  }
  return item;
}

function esc(s){
  return String(s??"").replace(/[&<>"']/g, m=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[m]));
}

function renderPreview(){
  let item;
  try { item=readForm(); }
  catch(e){ $("#preview").innerHTML=`<div class="error-list">JSON 오류: ${esc(e.message)}</div>`; return; }

  if(state.type==="cards"){
    $("#preview").innerHTML = `
      <div class="preview-card">
        <div class="energy">${esc(item.energy_cost)}</div>
        <div class="preview-title">${esc(item.name||"카드명")}</div>
        <div class="preview-meta">${esc(item.character)} · ${esc(item.rarity)} · ${esc(item.type)} · ${esc(item.target)}</div>
        <div class="preview-effect">${esc(item.description||"효과 설명")}</div>
        ${item.upgraded_description?`<hr><div class="preview-effect"><b>강화:</b> ${esc(item.upgraded_description)}</div>`:""}
      </div>`;
    return;
  }
  const main = item.name || item.title || item.id || "새 항목";
  const lines = Object.entries(item).filter(([k])=>!["name","title","id"].includes(k)).slice(0,9);
  $("#preview").innerHTML = `<div class="preview-generic"><div class="big">${esc(main)}</div>
    <div class="meta">${esc(item.id||"")}</div><pre>${esc(lines.map(([k,v])=>`${k}: ${typeof v==="object"?JSON.stringify(v):v}`).join("\n"))}</pre></div>`;
}

function renderList(){
  const list=$("#itemList");
  const q=$("#searchInput").value.trim().toLowerCase();
  const rows=(state.data[state.type]||[]).filter(x=>{
    const hay=`${x.id||""} ${x.name||""} ${x.title||""}`.toLowerCase();
    return hay.includes(q);
  });
  list.innerHTML="";
  if(!rows.length){ list.innerHTML=`<div style="color:#8f8187">항목 없음</div>`; return; }
  for(const item of rows){
    const div=document.createElement("div");
    div.className="item"+(state.current?.id===item.id?" active":"");
    div.innerHTML=`<div class="name">${esc(item.name||item.title||item.id)}</div><div class="id">${esc(item.id)}</div>`;
    div.onclick=()=>{ state.current=structuredClone(item); renderForm(); renderList(); };
    list.appendChild(div);
  }
}

function renderAll(){ renderTabs(); renderForm(); renderList(); }

async function reload(){
  state.data=await api("/api/data");
  renderAll();
}

async function init(){
  const sc=await api("/api/schema");
  state.schema=sc.schema; state.typeOrder=sc.type_order;
  state.data=await api("/api/data");
  const ho=await api("/api/handover");
  $("#hoGoal").value=ho.goal||"";
  $("#hoCompleted").value=ho.completed||"";
  $("#hoPending").value=ho.pending||"";
  $("#hoNotes").value=ho.notes||"";
  renderAll();
  status("준비됨");
}

$("#searchInput").addEventListener("input", renderList);
$("#btnNew").onclick=()=>{ state.current=null; renderForm(); renderList(); };
$("#btnSave").onclick=async()=>{
  try{
    const item=readForm();
    const res=await api("/api/item",{method:"POST",body:JSON.stringify({type:state.type,item})});
    state.current=structuredClone(item);
    await reload();
    status(`저장 완료: ${item.id}`);
  }catch(e){ status(e.message,false); }
};
$("#btnDelete").onclick=async()=>{
  try{
    const item=readForm();
    if(!item.id) throw new Error("삭제할 ID가 없습니다.");
    if(!confirm(`${item.id} 삭제?`)) return;
    await api(`/api/item?type=${encodeURIComponent(state.type)}&id=${encodeURIComponent(item.id)}`,{method:"DELETE"});
    state.current=null; await reload(); status("삭제 완료");
  }catch(e){ status(e.message,false); }
};
$("#btnValidate").onclick=async()=>{
  try{
    const r=await api("/api/validate");
    if(r.invalid===0) status(`검증 통과: ${r.valid}/${r.total}`);
    else{
      const errs=[];
      for(const [t,rows] of Object.entries(r.results)){
        for(const row of rows||[]) if(row.errors?.length) errs.push(`${t}/${row.id}: ${row.errors.join(", ")}`);
      }
      alert(`오류 ${r.invalid}개\n\n${errs.join("\n")}`);
      status(`검증 실패: ${r.invalid}개`,false);
    }
  }catch(e){ status(e.message,false); }
};
$("#btnExport").onclick=()=>$("#exportModal").classList.remove("hidden");
$("#doExport").onclick=async()=>{
  try{
    const godot_path=$("#godotPath").value.trim() || null;
    const r=await api("/api/export",{method:"POST",body:JSON.stringify({godot_path})});
    status(`Export 완료: ${r.export_dir}`);
    alert(`Export 완료\n${r.export_dir}${r.godot_written.length?`\nGodot: ${r.godot_written.length}개 파일`:""}`);
  }catch(e){ status(e.message,false); }
};
$("#btnHandover").onclick=()=>$("#handoverModal").classList.remove("hidden");
$("#doHandover").onclick=async()=>{
  try{
    const payload={goal:$("#hoGoal").value,completed:$("#hoCompleted").value,pending:$("#hoPending").value,notes:$("#hoNotes").value};
    const r=await api("/api/handover",{method:"POST",body:JSON.stringify(payload)});
    status(`인수인계 생성: ${r.path}`);
    alert(`생성 완료\n${r.path}`);
  }catch(e){ status(e.message,false); }
};
document.querySelectorAll("[data-close]").forEach(b=>b.onclick=()=>$("#"+b.dataset.close).classList.add("hidden"));
$("#btnComfyStatus").onclick=async()=>{
  try{
    const url=$("#comfyUrl").value.trim();
    const r=await api(`/api/comfy/status?url=${encodeURIComponent(url)}`);
    if(r.ok) status("ComfyUI 연결 성공");
    else status(`ComfyUI 연결 실패: ${r.error}`,false);
  }catch(e){ status(e.message,false); }
};
$("#btnGenerateArt").onclick=async()=>{
  try{
    const item=readForm();
    if(!item.id) throw new Error("먼저 ID를 입력하세요.");
    if(!item.art_prompt) throw new Error("아트 프롬프트가 비어 있습니다.");
    if((item.art_source||"AUTO")==="PREMIUM" || (item.art_source||"AUTO")==="MANUAL"){
      throw new Error(`${item.art_source} 자산은 ComfyUI 자동 생성 대상이 아닙니다.`);
    }
    await api("/api/item",{method:"POST",body:JSON.stringify({type:state.type,item})});
    const output=`generated/${state.type}/${item.id}.png`;
    status("ComfyUI 생성 중...");
    const r=await api("/api/comfy/generate",{method:"POST",body:JSON.stringify({
      url:$("#comfyUrl").value.trim(),
      type:state.type, id:item.id,
      prompt:item.art_prompt,
      output,
      prefix:`${state.type}_${item.id}`,
      width:state.type==="cards"?768:768,
      height:state.type==="cards"?1024:768
    })});
    const imageField = state.type==="relics"||state.type==="potions"||state.type==="enchants"||state.type==="powers" ? "icon":"image";
    const fieldEl=$("#form").querySelector(`[data-key="${imageField}"]`);
    if(fieldEl) fieldEl.value=r.output;
    const approval=$("#form").querySelector(`[data-key="approval_state"]`);
    if(approval) approval.value="needs_review";
    renderPreview();
    status(`ComfyUI 생성 완료: ${r.output}`);
  }catch(e){ status(e.message,false); }
};

init().catch(e=>status(e.message,false));
