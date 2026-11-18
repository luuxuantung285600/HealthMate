import {exerciseBackgroundProfiles} from './exercise-background-profiles.mjs';
// Reviewed enclosed backdrop seeds complement the border flood. No GIF bytes
// are read or copied; the filter follows each frame directly, including pause.
export const exerciseGifBackgroundId='healthmate-admin-exercise-background-v4';
const definitionsId='healthmate-admin-exercise-background-defs';

function filterMarkup(id,regions=[]) {
  let growth='';
  for(let i=0;i<180;i++) {
    growth+=`<feMorphology in="bg${i}" operator="dilate" radius="0.00556" result="grow${i}"/><feComposite in="grow${i}" in2="white" operator="in" result="bg${i+1}"/>`;
  }
  return `<filter id="${id}" x="-5%" y="-5%" width="110%" height="110%" primitiveUnits="objectBoundingBox" color-interpolation-filters="sRGB">`
    +'<feColorMatrix in="SourceGraphic" type="matrix" values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 100 100 100 0 -293" result="white"/>'
    +'<feMorphology in="SourceAlpha" operator="erode" radius="0.00556" result="inner"/>'
    +'<feComposite in="SourceAlpha" in2="inner" operator="out" result="border"/>'
    +seedMarkup(regions)
    +growth+'<feComposite in="SourceAlpha" in2="bg180" operator="out" result="subject"/>'
    +'<feMorphology in="subject" operator="erode" radius="0.00556" result="trim"/>'
    +'<feGaussianBlur in="trim" stdDeviation="0.00444" result="smooth"/>'
    +'<feComposite in="smooth" in2="subject" operator="in" result="matte"/>'
    +'<feColorMatrix in="matte" type="matrix" values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 1 0" result="whiteMatte"/>'
    +'<feComposite in="SourceGraphic" in2="whiteMatte" operator="arithmetic" k2="1" k3="1" k4="-1"/>'
    +'</filter>';
}


function seedMarkup(regions) {
  const u=n=>(n/180).toFixed(8);
  let markup='',inputs=['border'];
  regions.forEach(({seed,guards},i)=>{
    let previous=`seed${i}`;
    markup+=`<feFlood flood-color="white" x="${u(seed[0])}" y="${u(seed[1])}" width="${u(1)}" height="${u(1)}" result="${previous}"/>`;
    guards.forEach(([x,y,above,threshold],j)=>{
      const k=above?100:-100,offset=.5-k*threshold/255;
      const name=`guard${i}x${j}`;
      // A cropped source sample is tiled to gate the seed on the current pose.
      markup+=`<feColorMatrix in="SourceGraphic" type="matrix" values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 ${k} ${k} ${k} 0 ${offset}" x="${u(x)}" y="${u(y)}" width="${u(1)}" height="${u(1)}" result="${name}"/><feTile in="${name}" result="${name}tile"/><feComposite in="${previous}" in2="${name}tile" operator="in" result="${name}seed"/>`;
      previous=`${name}seed`;
    });
    inputs.push(previous);
  });
  return markup+'<feMerge result="seeds">'+inputs.map(name=>`<feMergeNode in="${name}"/>`).join('')+'</feMerge><feComposite in="seeds" in2="white" operator="in" result="bg0"/>';
}

export function exerciseGifBackgroundMarkup() {
  return '<defs>'+filterMarkup(exerciseGifBackgroundId)+Object.entries(exerciseBackgroundProfiles).map(([id,regions])=>filterMarkup(`${exerciseGifBackgroundId}-${id}`,regions)).join('')+'</defs>';
}

export function exerciseGifBackgroundStyles() {
  return Object.keys(exerciseBackgroundProfiles).map(id=>`:root[data-theme="dark"] .exercise-media-frame img[src^="https://static.exercisedb.dev/media/${id}.gif"],:root[data-theme="dark"] .exercise-detail-image[src^="https://static.exercisedb.dev/media/${id}.gif"],:root[data-theme="dark"] .exercise-source-thumb-image[data-source-id="${id}"]{filter:url(#${exerciseGifBackgroundId}-${id})}`).join('');
}

export function ensureExerciseGifBackground(document) {
  const installed=document.getElementById(definitionsId);
  if(installed?.querySelector(`#${exerciseGifBackgroundId}`))return;
  installed?.remove();
  const svg=document.createElementNS('http://www.w3.org/2000/svg','svg');
  svg.id=definitionsId;
  svg.setAttribute('aria-hidden','true');
  svg.setAttribute('focusable','false');
  svg.setAttribute('width','0');
  svg.setAttribute('height','0');
  svg.innerHTML=exerciseGifBackgroundMarkup();
  document.body.append(svg);
}
