; resourced by tmk
; visit Game Boy Compression Playground at https://github.com/gitendo/gbcp for more
; Mega Man Xtreme 2 (USA, Europe).gbc uses exactly the same routine

SECTION "Uncap Decompressor", ROM0

uncap::
	ld	a,[hl+]			; start with token
	and	a			; 0 marks the end of packed data
	ret	z
	bit	7,a			; next byte is offset if 7th bit is set
	jr	z,_literals             ; literals come next otherwise
	and	$7F			; bits 0 - 6 define reference length
	ld	c,a			; move length to c(ounter)
	ld	a,[hl+]			; load offset
	push	hl			; store packed data address
	ld	l,a			; offset is negative because game boy cpu lacks
	ld	h,$FF			; sub hl,de :)
	add	hl,de			; locate reference
_1:
	ld	a,[hl+]			; and copy it
	ld	[de],a
	inc	de
	dec	c
	jr	nz,_1
	pop	hl			; restore packed data address
	jr	uncap			; continue
_literals:
	ld	c,a			; move length to c(ounter)
_2:
	ld	a,[hl+]			; and copy c literals
	ld	[de],a
	inc	de
	dec	c
	jr	nz,_2
	jr	uncap			; continue