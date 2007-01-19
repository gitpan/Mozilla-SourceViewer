#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <nsCOMPtr.h>
#include <nsEmbedCID.h>
#include <docshell/nsIDocShell.h>
#include <docshell/nsIWebPageDescriptor.h>
#include <nsIInterfaceRequestorUtils.h>
#include <widget/nsIBaseWindow.h>
#include <nsComponentManagerUtils.h>
#include <docshell/nsIDocShellTreeItem.h>
#include <gtkmozembed2perl.h>
#include <nsIWebProgressListener.h>
#include <nsWeakReference.h>
#include <nsStringAPI.h>
#include <xpcom/nsCRT.h>

#undef Move
#include <nsIContentViewer.h>
#include <nsIContentViewerEdit.h>


class PListener : public nsIWebProgressListener, public nsSupportsWeakReference
{
public:
    PListener() : starts_(0) {}
    
    NS_DECL_ISUPPORTS
    NS_DECL_NSIWEBPROGRESSLISTENER

	/* There is one start more than stop */
	int is_loading() const { return this->starts_ > 1; }

private:
    int starts_;
    
};

NS_IMPL_ISUPPORTS2(PListener, nsIWebProgressListener, nsISupportsWeakReference)

NS_IMETHODIMP
PListener::OnStateChange(nsIWebProgress *aWebProgress,
			     nsIRequest     *aRequest,
			     PRUint32        flags,
			     nsresult        aStatus)
{
	/*
	fprintf(stderr, "# %p OnStateChange: %x %d %d %d %d %d\n"
		, this, flags, flags & STATE_START, flags & STATE_STOP
		, this->load_complete_
		, !!(flags & STATE_IS_REQUEST)
		, !!(flags & STATE_IS_DOCUMENT));
	*/

	if (flags & STATE_START)
		this->starts_++;

	if (flags & STATE_STOP)
		this->starts_--;
	return NS_OK;
}

NS_IMETHODIMP
PListener::OnProgressChange(nsIWebProgress *aWebProgress,
				nsIRequest     *aRequest,
				PRInt32         aCurSelfProgress,
				PRInt32         aMaxSelfProgress,
				PRInt32         aCurTotalProgress,
				PRInt32         aMaxTotalProgress)
{
    return NS_OK;
}

NS_IMETHODIMP
PListener::OnLocationChange(nsIWebProgress *aWebProgress,
				nsIRequest     *aRequest,
				nsIURI         *aLocation)
{
    return NS_OK;
}



NS_IMETHODIMP
PListener::OnStatusChange(nsIWebProgress  *aWebProgress,
			      nsIRequest      *aRequest,
			      nsresult         aStatus,
			      const PRUnichar *aMessage)
{
    return NS_OK;
}



NS_IMETHODIMP
PListener::OnSecurityChange(nsIWebProgress *aWebProgress,
				nsIRequest     *aRequest,
				PRUint32         aState)
{
    return NS_OK;
}

MODULE = Mozilla::SourceViewer		PACKAGE = Mozilla::SourceViewer		

nsEmbedString
Get_Page_Source(me)
	GtkMozEmbed *me;
	INIT:
		nsresult rv = !NS_OK;
	CODE:
		nsCOMPtr<nsIWebBrowser> old_bro, new_bro;
		nsCOMPtr<nsIDocShell> old_doc_shell, new_doc_shell;
		nsCOMPtr<nsIWebPageDescriptor> old_page_desc, new_page_desc;
		nsCOMPtr<nsISupports> page_cookie;
		nsCOMPtr<nsIDocShellTreeItem> item;
		nsCOMPtr<nsIBaseWindow> base_window;
		nsCOMPtr<nsISupports> lis;
		nsCOMPtr<nsIWeakReference> weak_ref;
		GtkWidget *owner;
		PListener *plis;
		nsCOMPtr<nsIContentViewer> content_viewer;
		nsCOMPtr<nsIContentViewerEdit> content_vi;
		nsCOMPtr<nsIDOMWindow> dom_win;
		nsCOMPtr<nsISelection> selection;
		PRUnichar *sel_str;
		nsEmbedString res;

		gtk_moz_embed_get_nsIWebBrowser(me, getter_AddRefs(old_bro));
		if (!old_bro)
			goto out_retval;

     		old_doc_shell = do_GetInterface(old_bro);
		if (!old_doc_shell)
			goto out_retval;

    		old_page_desc = do_GetInterface(old_doc_shell);
		if (!old_page_desc)
			goto out_retval;

		rv = old_page_desc->GetCurrentDescriptor(
				getter_AddRefs(page_cookie));
		if (NS_FAILED(rv))
			goto out_retval;

		new_bro = do_CreateInstance(NS_WEBBROWSER_CONTRACTID);
		if (!new_bro)
			goto out_retval;

		new_bro->SetContainerWindow(nsnull);
		item = do_QueryInterface(new_bro);
		if (!item)
			goto out_retval;

		item->SetItemType(nsIDocShellTreeItem::typeContentWrapper);

		owner = gtk_invisible_new();
		if (!owner)
			goto out_retval;

		base_window = do_QueryInterface(new_bro);
		if (!base_window)
			goto out_retval;

		rv = base_window->InitWindow(owner, nsnull, 0, 0
				, owner->allocation.width
				, owner->allocation.height);
		if (NS_FAILED(rv))
			goto out_retval;

		rv = base_window->Create();
		if (NS_FAILED(rv))
			goto out_retval;
		rv = !NS_OK;

		plis = new PListener;
		lis = NS_STATIC_CAST(nsIWebProgressListener *, plis);
		weak_ref = do_GetWeakReference(lis);
		if (!weak_ref)
			goto out_retval;

    		rv = new_bro->AddWebBrowserListener(weak_ref
				, NS_GET_IID(nsIWebProgressListener));
		if (NS_FAILED(rv))
			goto out_retval;
		rv = !NS_OK;

		new_doc_shell = do_GetInterface(new_bro);
		if (!new_doc_shell)
			goto out_retval;

		new_page_desc = do_GetInterface(new_doc_shell);
		if (!new_page_desc)
			goto out_retval;

		rv = new_page_desc->LoadPage(page_cookie
				, nsIWebPageDescriptor::DISPLAY_AS_SOURCE);
		if (NS_FAILED(rv))
			goto out_retval;

		do {
			while(gtk_events_pending()) {
				gtk_main_iteration();
			}
		} while (plis->is_loading());

		new_doc_shell->GetContentViewer(getter_AddRefs(content_viewer));
		if (!content_viewer)
			goto out_retval;

		content_vi = do_QueryInterface(content_viewer);
		if (!content_vi)
			goto out_retval;

		rv = content_vi->SelectAll();
		if (NS_FAILED(rv))
			goto out_retval;

		new_bro->GetContentDOMWindow(getter_AddRefs(dom_win));
		if (!dom_win)
			goto out_retval;

		dom_win->GetSelection(getter_AddRefs(selection));
		if (!selection)
			goto out_retval;

		rv = selection->ToString(&sel_str);
		if (NS_FAILED(rv))
			goto out_retval;

		res = sel_str;
		nsMemory::Free(sel_str);
out_retval:
		RETVAL = res;
	OUTPUT:
		RETVAL
